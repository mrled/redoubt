import SwiftUI
import Foundation


enum VisualizationMode: String, Codable, CaseIterable, Identifiable {
    case Sha512
    
    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .Sha512: return "SHA512 hash"
        }
    }
}


struct RegularIntervalScheduleControls: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    
    var body: some View {
        Group {
            if secretsVm.regularIntervalNotifications.count > 0 {
                // WARNING: you cannot ForEach over a bound array and bind each element to a new child view!!!
                // If you do, Xcode will give you the most insane errors, and put them on the wrong line.
                // Instead you have to ForEach over indices, like this:
                ForEach(secretsVm.regularIntervalNotifications.indices, id: \.self) { index in
                    let dateBinding = Binding<Date>(
                        get: {
                            Calendar.current.date(from: secretsVm.regularIntervalNotifications[index]) ?? Date()
                        },
                        set: {
                            secretsVm.regularIntervalNotifications[index] = Calendar.current.dateComponents([.hour, .minute], from: $0)
                        }
                    )
                    TimePickerExpandable(date: dateBinding)
                }
                .onDelete(perform: removeScheduleTime)
            } else {
                Text("No time set, will not send notification")
                    .foregroundColor(.gray)
            }
            Button("Add a time", action: addScheduleTime)
        }
    }
     
    func addScheduleTime() {
        secretsVm.regularIntervalNotifications.append(
            Calendar.current.dateComponents([.hour, .minute], from: Date())
        )
    }

    func removeScheduleTime(at offsets: IndexSet) {
        for index in offsets {
            secretsVm.regularIntervalNotifications.remove(at: index)
        }
    }
}


struct SpacedRepetitionScheduleControls: View {
    @EnvironmentObject var secretsVm: SecretsViewModel

    var body: some View {
        Group {
            Text("Redoubt will prompt you for passwords at these intervals")
                .foregroundColor(.gray)
            ForEach(secretsVm.spacedRepetitionCategories) { category in
                Text("    \(category.name)")
                    .foregroundColor(.gray)
            }
            // TODO: show the time the notification will be delivered
            // TODO: allow setting a daily time range like 9-5
        }
    }
}


// MARK: - Notification Slots Editor

struct NotificationSlotsEditor: View {
    @Binding var slots: [DateComponents]
    let schedule: ReviewSchedule
    let onSlotsChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notification Times")
                .font(.headline)

            ForEach(slots.indices, id: \.self) { index in
                HStack {
                    Text(schedule.labelForSlot(at: index))
                        .frame(width: 80, alignment: .leading)

                    if let range = allowedRange(for: index) {
                        DatePicker(
                            "",
                            selection: binding(for: index),
                            in: range,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    } else {
                        DatePicker(
                            "",
                            selection: binding(for: index),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }
            }

            if schedule.requiresSlotSpacing {
                Text("Times must be at least \(schedule.formattedMinimumBuffer()) apart")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    private func allowedRange(for index: Int) -> ClosedRange<Date>? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let buffer = schedule.minimumSlotBuffer

        // For single-slot schedules, no constraint needed
        if slots.count == 1 {
            return nil
        }

        // For the first slot, constrain based on what comes after
        if index == 0, slots.count > 1 {
            // Morning must leave enough time for Evening (and wrap-around)
            let nextSlotTime = calendar.date(from: slots[index + 1]) ?? today
            let maxTime = calendar.date(byAdding: .second, value: -Int(buffer), to: nextSlotTime) ?? today

            // Ensure valid range (maxTime must be >= today)
            guard maxTime >= today else { return nil }

            // Allow from start of day to (nextSlot - buffer)
            return today...maxTime
        }

        // For subsequent slots, constrain based on what came before
        if index > 0 {
            let prevSlotTime = calendar.date(from: slots[index - 1]) ?? today
            let minTime = calendar.date(byAdding: .second, value: Int(buffer), to: prevSlotTime) ?? today

            // For the last slot, also check wrap-around to first slot
            if index == slots.count - 1 {
                let firstSlotTime = calendar.date(from: slots[0]) ?? today
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? today
                let maxTimeBeforeWrap = calendar.date(byAdding: .second, value: -Int(buffer), to: endOfDay.addingTimeInterval(firstSlotTime.timeIntervalSince(today))) ?? endOfDay

                // Ensure valid range
                guard maxTimeBeforeWrap >= minTime else { return nil }

                return minTime...maxTimeBeforeWrap
            }

            // For middle slots, constrain by next slot too
            if index < slots.count - 1 {
                let nextSlotTime = calendar.date(from: slots[index + 1]) ?? today
                let maxTime = calendar.date(byAdding: .second, value: -Int(buffer), to: nextSlotTime) ?? today

                // Ensure valid range
                guard maxTime >= minTime else { return nil }

                return minTime...maxTime
            }

            // Last slot only constrained by previous
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            return minTime...endOfDay
        }

        return nil // First slot with no others, no constraint
    }

    private func binding(for index: Int) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: slots[index]) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                slots[index] = components
                onSlotsChanged()
            }
        )
    }
}


// MARK: - New Schedule Controls

struct NewScheduleControls: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    @Binding var notificationsAllowed: Bool

    @State private var selectedScheduleId: UUID?
    @State private var notificationsEnabled: Bool = false
    @State private var customSlots: [DateComponents] = []

    var body: some View {
        Section("Schedule") {
            if notificationsAllowed {
                notificationsToggle

                if notificationsEnabled {
                    schedulePicker

                    if let schedule = currentSchedule() {
                        NotificationSlotsEditor(
                            slots: $customSlots,
                            schedule: schedule,
                            onSlotsChanged: { secretsVm.notificationSlots = customSlots }
                        )
                    }
                }
            } else {
                notificationPermissionPrompt
            }
        }
        .onAppear(perform: initializeState)
    }

    // MARK: - Subviews

    private var notificationsToggle: some View {
        Toggle(isOn: $notificationsEnabled) {
            HStack {
                Image(systemName: "bell.fill")
                    .frame(width: 32, height: 32)
                Text("Notifications enabled")
            }
        }
        .onChange(of: notificationsEnabled) { enabled in
            secretsVm.activeScheduleId = enabled
                ? (selectedScheduleId ?? secretsVm.availableSchedules.first?.id)
                : nil
        }
    }

    private var schedulePicker: some View {
        Picker(selection: $selectedScheduleId, label: Text("Schedule")) {
            ForEach(secretsVm.availableSchedules) { schedule in
                Text(schedule.name).tag(schedule.id as UUID?)
            }
        }
        .onChange(of: selectedScheduleId, perform: handleScheduleChange)
    }

    private var notificationPermissionPrompt: some View {
        Group {
            Text("To schedule reminders, please enable notifications in Settings.")
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                RowItemUrlWithIcon(title: "Open Settings", systemImageName: "gear", destination: url)
            }
        }
    }

    // MARK: - Helper Methods

    private func initializeState() {
        selectedScheduleId = secretsVm.activeScheduleId ?? secretsVm.availableSchedules.first?.id
        notificationsEnabled = secretsVm.activeScheduleId != nil

        // Initialize custom slots
        if let slots = secretsVm.notificationSlots {
            customSlots = slots
        } else if let schedule = currentSchedule() {
            customSlots = schedule.defaultSlots
        }
    }

    private func handleScheduleChange(_ newScheduleId: UUID?) {
        secretsVm.activeScheduleId = newScheduleId

        // Reset notification slots to schedule defaults when schedule changes
        if let schedule = secretsVm.availableSchedules.first(where: { $0.id == newScheduleId }) {
            customSlots = schedule.defaultSlots
            secretsVm.notificationSlots = nil // Use schedule defaults
        }
    }

    private func currentSchedule() -> ReviewSchedule? {
        guard let scheduleId = selectedScheduleId else { return nil }
        return secretsVm.availableSchedules.first(where: { $0.id == scheduleId })
    }
}


struct ScheduleControls: View {
    @Binding var notificationsAllowed: Bool
    @AppStorage(MFAStorage.K.scheduleType) var scheduleType: ScheduleType = MFAStorage.D.scheduleType

    var body: some View {
        Section("Schedule") {
            if notificationsAllowed {
                Picker(selection: $scheduleType, label: Text("Schedule type")) {
                    ForEach(ScheduleType.allCases) { schedType in
                        Text(schedType.description).tag(schedType)
                    }
                }
                .onChange(of: scheduleType) { newValue in
                    // TODO: cancel all notifications from previous selection, add notifications from new selection
                    switch newValue {
                    case .disabled:
                        break
                    case .daily:
                        break
                    case .spacedRepetition:
                        break
                    }
                }

                switch scheduleType {
                case .disabled:
                    EmptyView()
                case .daily:
                    RegularIntervalScheduleControls()
                case .spacedRepetition:
                    SpacedRepetitionScheduleControls()
                }
            } else {
                Text("To schedule reminders, please enable notifications in Settings.")
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        RowItemUrlWithIcon(title: "Open Settings", systemImageName: "gear", destination: url)
                    }
                }
            }
        }
    }
}


struct SettingsControls: View {
    @Binding var showOnboarding: Bool
    @Binding var showDeveloperOptions: Bool
    @Binding var enableEasterEggs: Bool
    @Binding var visualizationMode: VisualizationMode
    @Binding var demoMode: Bool
    var body: some View {
        Section("Settings") {
            // Not sure if it's the Toggles or what, but the spacing doesn't match RowItemWithIcon.
            // Just make them all HStack{Image, Text} and they look the same.
            Toggle(isOn: $showOnboarding) {
                // is a RowItemWithIcon except the Icon is a ShimmeringSystemImage
                HStack {
                    ShimmeringSystemImage(systemName: "play")
                        .frame(width: 32, height: 32)
                    Text("Show the onboarding button")
                }
            }
            Toggle(isOn: $enableEasterEggs) {
                HStack {
                    Image(systemName: "sparkles")
                        .frame(width: 32, height: 32)
                    Text("Enable easter eggs")
                }
            }
            HStack {
                Image(systemName: "sparkles.tv")
                    .frame(width: 32, height: 32)
                Picker(selection: $visualizationMode, label: Text("Visualization type")) {
                    ForEach(VisualizationMode.allCases) { possibleVizMode in
                        Text(possibleVizMode.description).tag(possibleVizMode)
                    }
                }
            }
            Toggle(isOn: $showDeveloperOptions) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 32, height: 32)
                    Text("Show developer options")
                }
            }
            NavigationLink(destination: DemoModeSheet(isPresentingDemoMode: .constant(false))) {
                HStack {
                    Image(systemName: "tv")
                        .frame(width: 32, height: 32)
                    if demoMode {
                        Text("Demo mode (currently enabled)")
                    } else {
                        Text("Demo mode (currently disabled)")
                    }
                }
            }
        }
    }
}

struct DeveloperOptions: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    
    var body: some View {
        Section("Developer") {
            NavigationLink(destination: DevNotifications()) {
                Text("Notifications debugger")
            }
            NavigationLink(destination: DevHapticPlayground()) {
                Text("Haptic playground")
            }
            if secretsVm.secrets.isEmpty {
                Text("Add a secret to enable the text field playground")
            } else {
                NavigationLink(destination: DevTextFieldPlayground(currentSecretId: .constant(secretsVm.secrets[0].id))) {
                    Text("Text field playground")
                }
            }
        }
    }
}

struct SettingsSheet: View {
    @Binding var notificationsAllowed: Bool
    @AppStorage(MFAStorage.K.enableEasterEggs) var enableEasterEggs: Bool = MFAStorage.D.enableEasterEggs
    @AppStorage(MFAStorage.K.showDeveloperOptions) var showDeveloperOptions: Bool = MFAStorage.D.showDeveloperOptions
    @AppStorage(MFAStorage.K.showOnboarding) var showOnboarding: Bool = MFAStorage.D.showOnboarding
    @AppStorage(MFAStorage.K.visualizationMode) var visualizationMode: VisualizationMode = MFAStorage.D.visualizationMode
    @AppStorage(MFAStorage.K.demoMode) var demoMode: Bool = MFAStorage.D.demoMode
    @State private var scheduleEveryXDays: Int = 1

    var body: some View {
        VStack {
            NavigationView {
                List {
                    NewScheduleControls(notificationsAllowed: $notificationsAllowed)
                    SettingsControls(
                        showOnboarding: $showOnboarding,
                        showDeveloperOptions: $showDeveloperOptions,
                        enableEasterEggs: $enableEasterEggs,
                        visualizationMode: $visualizationMode,
                        demoMode: $demoMode
                    )
                    Section("About") {
                        NavigationLink(destination: AboutSheet()) {
                            Text("About Redoubt")
                        }
                    }
                    if showDeveloperOptions {
                        DeveloperOptions()
                    }
                }
                .navigationBarTitle("Settings", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DemoNavbarToolbarButton()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", plaintext: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
        ]
        let exampleCollection = SecretCollection(secrets: exampleSecrets, regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
        let secretsPreviewVmTwoSecretsNoSchedules = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollection))

        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(secretsPreviewVmTwoSecretsNoSchedules)
            }
            .previewDisplayName("Simple, no schedules")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(secretsPreviewVmTwoSecretsNoSchedules)
                }
                .previewDisplayName("Simple, one schedule")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(false))
                        .environmentObject(secretsPreviewVmTwoSecretsNoSchedules)
                }
                .previewDisplayName("Notifications not allowed")
        }
    }
}
