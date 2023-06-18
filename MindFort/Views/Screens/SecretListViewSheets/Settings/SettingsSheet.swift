//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

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
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    
    var body: some View {
        Group {
            if notificationsModel.regularIntervalEntries.count > 0 {
                // WARNING: you cannot ForEach over a bound array and bind each element to a new child view!!!
                // If you do, Xcode will give you the most insane errors, and put them on the wrong line.
                // Instead you have to ForEach over indices, like this:
                ForEach(notificationsModel.regularIntervalEntries.indices, id: \.self) { index in
                    let dateBinding = Binding<Date>(
                        get: {
                            Calendar.current.date(from: notificationsModel.regularIntervalEntries[index]) ?? Date()
                        },
                        set: {
                            notificationsModel.regularIntervalEntries[index] = Calendar.current.dateComponents([.hour, .minute], from: $0)
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
        notificationsModel.regularIntervalEntries.append(
            Calendar.current.dateComponents([.hour, .minute], from: Date())
        )
    }

    func removeScheduleTime(at offsets: IndexSet) {
        for index in offsets {
            notificationsModel.regularIntervalEntries.remove(at: index)
        }
    }
}


struct SpacedRepetitionScheduleControls: View {
    @EnvironmentObject var spacedRepCategoriesVM: SpacedRepCategoriesViewModel

    var body: some View {
        Group {
            Text("MindFort will prompt you for passwords at these intervals")
                .foregroundColor(.gray)
            ForEach(spacedRepCategoriesVM.categories) { category in
                Text("    \(category.name)")
                    .foregroundColor(.gray)
            }
            // TODO: show the time the notification will be delivered
            // TODO: allow setting a daily time range like 9-5
        }
    }
}


struct ScheduleControls: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
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
                switch scheduleType {
                case .disabled:
                    EmptyView()
                case .daily:
                    RegularIntervalScheduleControls()
                        .environmentObject(notificationsModel)
                case .spacedRepetition:
                    SpacedRepetitionScheduleControls()
                        .environmentObject(notificationsModel)
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
    
//    /// Combine the hours-and-minutes-only .scheduleTimes.dateComponents
//    /// with the days/weeks/months controlled by scheduleEveryXDays
//    var scheduleItems: [DateComponents] {
//        if !scheduleEnabled {
//            return []
//        }
//        let result: [DateComponents] = []
//        for time in scheduleTimes {
//            var component = DateComponents(
//        }
//        return result
//    }
}


struct SettingsControls: View {
    @Binding var showOnboarding: Bool
    @Binding var showDeveloperOptions: Bool
    @Binding var enableEasterEggs: Bool
    @Binding var visualizationMode: VisualizationMode
    @Binding var demoMode: Bool
    @State private var isPresentingDemoModeSheet = false
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
            Button(action: { isPresentingDemoModeSheet = true }) {
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
        .sheet(isPresented: $isPresentingDemoModeSheet) {
            DemoModeSheet(isPresentingDemoMode: $isPresentingDemoModeSheet)
        }
    }
}

struct DeveloperOptions: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @EnvironmentObject var secretsModel: SecretsViewModel
    
    var body: some View {
        Section("Developer") {
            NavigationLink(destination: DevNotifications().environmentObject(notificationsModel)) {
                Text("Notifications debugger")
            }
            NavigationLink(destination: DevHapticPlayground()) {
                Text("Haptic playground")
            }
            if secretsModel.secrets.isEmpty {
                Text("Add a secret to enable the text field playground")
            } else {
                NavigationLink(destination: DevTextFieldPlayground(currentSecretId: .constant(secretsModel.secrets[0].id))) {
                    Text("Text field playground")
                }
                .environmentObject(secretsModel)
            }
        }
    }
}

struct SettingsSheet: View {
    @Binding var notificationsAllowed: Bool
    @AppStorage(MFAStorage.K.enableEasterEggs) var enableEasterEggs: Bool = MFAStorage.D.enableEasterEggs
    @AppStorage(MFAStorage.K.showDeveloperOptions) var showDeveloperOptions: Bool = MFAStorage.D.showDeveloperOptions
    @AppStorage(MFAStorage.K.scheduleType) var scheduleType: ScheduleType = MFAStorage.D.scheduleType
    @AppStorage(MFAStorage.K.showOnboarding) var showOnboarding: Bool = MFAStorage.D.showOnboarding
    @AppStorage(MFAStorage.K.visualizationMode) var visualizationMode: VisualizationMode = MFAStorage.D.visualizationMode
    @AppStorage(MFAStorage.K.demoMode) var demoMode: Bool = MFAStorage.D.demoMode
    @State private var scheduleEveryXDays: Int = 1
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @EnvironmentObject var secretsModel: SecretsViewModel

    var body: some View {
        VStack {
            NavigationView {
                List {
                    ScheduleControls(notificationsAllowed: $notificationsAllowed)
                        .environmentObject(notificationsModel)
                    SettingsControls(
                        showOnboarding: $showOnboarding,
                        showDeveloperOptions: $showDeveloperOptions,
                        enableEasterEggs: $enableEasterEggs,
                        visualizationMode: $visualizationMode,
                        demoMode: $demoMode
                    )
                    Section("About") {
                        NavigationLink(destination: AboutSheet()) {
                            Text("About MindFort")
                        }
                        NavigationLink(destination: Roadmap()) {
                            Text("Development Roadmap")
                        }
                    }
                    if showDeveloperOptions {
                        DeveloperOptions()
                            .environmentObject(notificationsModel)
                            .environmentObject(secretsModel)
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
        let secretsModelTwoSecrets = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleSecrets))
        let notificationsVmNoSchedules = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
        let spacedRepCategoriesVM = SpacedRepCategoriesViewModel()

        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(notificationsVmNoSchedules)
                        .environmentObject(secretsModelTwoSecrets)
                        .environmentObject(spacedRepCategoriesVM)
            }
            .previewDisplayName("Simple, no schedules")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(notificationsVmNoSchedules)
                        .environmentObject(secretsModelTwoSecrets)
                        .environmentObject(spacedRepCategoriesVM)
                }
                .previewDisplayName("Simple, one schedule")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(false))
                        .environmentObject(notificationsVmNoSchedules)
                        .environmentObject(secretsModelTwoSecrets)
                        .environmentObject(spacedRepCategoriesVM)
                }
                .previewDisplayName("Notifications not allowed")
        }
    }
}
