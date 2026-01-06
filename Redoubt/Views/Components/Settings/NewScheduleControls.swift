import SwiftUI
import Foundation

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

#Preview {
    let exampleSecrets = [
        try! Secret(name: "Secure passphrase", plaintext: "password"),
        try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
    ]
    let exampleCollection = SecretCollection(secrets: exampleSecrets, regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
    let secretsPreviewVm = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollection))

    return NavigationStack {
        List {
            NewScheduleControls(notificationsAllowed: .constant(true))
                .environmentObject(secretsPreviewVm)
        }
    }
}
