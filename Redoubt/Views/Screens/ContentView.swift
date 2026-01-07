import SwiftUI
import CryptoKit


struct ContentView: View {
    @StateObject private var notificationActionHandler = NotificationActionHandler.shared
    @EnvironmentObject var secretsVm: SecretsViewModel
    @State private var notificationsAllowed: Bool = false
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        SecretListView(openAction: $notificationActionHandler.openAction, notificationsAllowed: $notificationsAllowed)
            .onAppear(perform: {
                // The action key is set by the notification delegate.
                // We want to unset it as soon as we launch,
                // so that it only applies when the user is launching the app by tapping on the notification.
                UserDefaults.standard.removeObject(forKey: MFAStorage.K.notificationAction)
            })
            .onChange(of: scenePhase) { newScenePhase in
                // Only re-evaluate notifications when the app becomes active
                // This prevents unnecessary calls when the app goes to background or becomes inactive
                if newScenePhase == .active {
                    // Check authorization status without requesting permission
                    // Only reregister if already authorized, don't prompt if notDetermined
                    NotificationManager.shared.getAuthorizationStatus { status in
                        let granted = status == .authorized
                        notificationsAllowed = granted

                        // Re-evaluate and update notifications based on current state
                        // This handles cases where secrets may have become due while the app was inactive
                        if granted {
                            secretsVm.notificationManager.reregisterAllNotifications()
                        }
                    }
                }
            }
    }
}
