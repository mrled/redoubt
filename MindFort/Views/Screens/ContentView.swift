import SwiftUI
import CryptoKit


struct ContentView: View {
    @StateObject private var notificationActionHandler = NotificationActionHandler.shared
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
                /// This code runs whenever the scene changes phases.
                /// That includes when the app becomes active, inactive, and backgrounsed. (Maybe more?)
                NotificationManager.shared.requestPermission { granted in
                    notificationsAllowed = granted
                }
            }
    }
}
