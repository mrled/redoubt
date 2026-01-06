import SwiftUI
import Foundation


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
