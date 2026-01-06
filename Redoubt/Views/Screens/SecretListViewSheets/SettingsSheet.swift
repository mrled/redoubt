import SwiftUI
import Foundation


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
        let exampleCollection = SecretCollection(secrets: exampleSecrets, regularIntervalNotifications: [], oneTimeNotifications: [])
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
