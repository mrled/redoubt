import SwiftUI


class AppDelegate: UIResponder, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Required to let notifications open different views than the regular app view, etc
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        return true
    }
}


@main
struct RedoubtApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var secretsVm: SecretsViewModel
    
    init() {
        // We can't reference the class demoMode variable here because, we're in the initializer. bleh
        var storage = MFUDStorage()
        let fileStorage = MFFStorage()

        // Auto-enable demo mode in simulator
        #if targetEnvironment(simulator)
        storage.demoMode = true
        let demoDataLoader = SecretsVmDataLoaderFromPlist(collectionPlist: fileStorage.secretsDemoPlist)
        // In the sim, a fresh batch of demo secrets on every app launch.
        demoDataLoader.save(collection: getDemoModeSecretCollection())
        #endif

        let initDemoMode = storage.demoMode
        if initDemoMode {
            _secretsVm = StateObject(wrappedValue: SecretsViewModel(dataLoader: SecretsVmDataLoaderFromPlist(collectionPlist: fileStorage.secretsDemoPlist)))
        } else {
            _secretsVm = StateObject(wrappedValue: SecretsViewModel(dataLoader: SecretsVmDataLoaderFromPlist(collectionPlist: fileStorage.secretsUserPlist)))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(secretsVm)
        }
    }
}
