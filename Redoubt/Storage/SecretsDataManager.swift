import Foundation

/**
 * Handles data persistence and demo mode switching for secrets.
 * 
 * Manages plist storage, UserDefaults monitoring, and automatic data loading
 * when switching between demo and production modes.
 */
class SecretsDataManager: ObservableObject {
    weak var secretsViewModel: SecretsViewModel?
    
    /// An implementation of the DataLoader protocol lets us swap out data storage.
    /// When the app is running, we use a plist; in tests and preview functions we can use a simple array backend.
    private var dataLoader: SecretsVmDataLoader
    
    /// Track whether we're in demo mode
    private var inDemoMode: Bool
    
    /// An observer for UserDefaults to track whether we're in demo mode
    private var userDefautlsObserver: Any?
    
    /// A URL for the document directory that the initializer ensures exists, just a convenience to not have to deal with optionals
    let documents: URL

    /// Our data is stored here
    var secretsUserPlist: URL { documents.appendingPathComponent("SecretsUser.plist") }
    
    /// In demo mode, our data is stored here
    var secretsDemoPlist: URL { documents.appendingPathComponent("SecretsDemo.plist") }
    
    init(dataLoader: SecretsVmDataLoader? = nil) {
        if let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            documents = d
        } else {
            fatalError("Unable to access documents directory.")
        }
        
        // Why use UserDefaults here, which requires adding the Observer below,
        // when AppStorage is supposed to handle observability for us?
        // Because AppStorage can only do that automatically in a SwiftUI View,
        // and was really only intended to be used in View code.
        inDemoMode = UserDefaults.standard.bool(forKey: "demoMode")
        
        let secretsPlist = inDemoMode ? MFFStorage().secretsDemoPlist : MFFStorage().secretsUserPlist
        
        self.dataLoader = dataLoader ?? SecretsVmDataLoaderFromPlist(collectionPlist: secretsPlist)
        
        // This listens for changes on ANY UserDefaults key, lol
        // TODO: replace this with something that only listens to the specific key we care about
        userDefautlsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            // We don't get the new value for demoMode
            self?.userDefaultsDidChange()
        }
    }
    
    func setSecretsViewModel(_ viewModel: SecretsViewModel) {
        self.secretsViewModel = viewModel
    }
    
    deinit {
        if let observer = userDefautlsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// If UserDefaults changes, check whether we've transitioned to/from demo mode.
    /// If we have, throw away the secrets etc from the old mode, and load secrets from the new mode.
    func userDefaultsDidChange() {
        let oldDemoMode = inDemoMode
        inDemoMode = UserDefaults.standard.bool(forKey: "demoMode")
        if inDemoMode != oldDemoMode {
            let secretsPlist = inDemoMode ? secretsDemoPlist : secretsUserPlist
            dataLoader = SecretsVmDataLoaderFromPlist(collectionPlist: secretsPlist)
            if inDemoMode {
                // If we are transitioning to demo mode from regular mode,
                // we want a clean slate with a default list of passwords
                dataLoader.save(collection: getDemoModeSecretCollection())
            }
            loadItems()
        }
    }
    
    func saveItems() {
        guard let viewModel = secretsViewModel else { return }
        let collection = SecretCollection(
            secrets: viewModel.secrets,
            regularIntervalNotifications: viewModel.regularIntervalNotifications,
            oneTimeNotifications: viewModel.oneTimeNotifications,
            spacedRepetitionCategories: viewModel.spacedRepetitionCategories,
            availableSchedules: viewModel.availableSchedules,
            activeScheduleId: viewModel.activeScheduleId,
            notificationSlots: viewModel.notificationSlots
        )
        dataLoader.save(collection: collection)
    }
    
    func loadItems() {
        guard let viewModel = secretsViewModel else { return }
        let collection = dataLoader.load()
        viewModel.secrets = collection.secrets
        viewModel.regularIntervalNotifications = collection.regularIntervalNotifications
        viewModel.oneTimeNotifications = collection.oneTimeNotifications

        // If loaded spaced repetition categories are empty, populate with defaults
        if collection.spacedRepetitionCategories.isEmpty {
            viewModel.spacedRepetitionCategories = getDefaultSpacedRepetitionCategories()
            // Save the updated collection with default categories
            saveItems()
        } else {
            viewModel.spacedRepetitionCategories = collection.spacedRepetitionCategories
        }

        // Load new schedule system fields
        viewModel.availableSchedules = collection.availableSchedules
        viewModel.activeScheduleId = collection.activeScheduleId
        viewModel.notificationSlots = collection.notificationSlots

        viewModel.publisherManager.setupPublishers()
    }
    
    func deleteAllData() {
        guard let viewModel = secretsViewModel else { return }
        viewModel.secrets = []
        viewModel.regularIntervalNotifications = []
        viewModel.oneTimeNotifications = []
        viewModel.spacedRepetitionCategories = []
        
        dataLoader.deleteAllData()
        viewModel.publisherManager.setupPublishers()
        
        viewModel.notificationManager.reregisterAllNotifications()
    }
    
    /// Creates the default spaced repetition categories
    private func getDefaultSpacedRepetitionCategories() -> [SpacedRepetitionCategory] {
        return [
            SpacedRepetitionCategory(name: "Daily", description: "", duration: 60 * 60 * 24),
            SpacedRepetitionCategory(name: "Every 3 days", description: "", duration: 60 * 60 * 24 * 3),
            SpacedRepetitionCategory(name: "Weekly", description: "", duration: 60 * 60 * 24 * 7),
            SpacedRepetitionCategory(name: "Every 2 weeks", description: "", duration: 60 * 60 * 24 * 7 * 2),
            SpacedRepetitionCategory(name: "Monthly", description: "", duration: 60 * 60 * 24 * 31),
        ]
    }
}
