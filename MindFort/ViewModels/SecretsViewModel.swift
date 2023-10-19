//
//  SecretListViewModel.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation
import Combine


class SecretsViewModel: ObservableObject {
    /// The type of notification schedule
    @Published var scheduleType: ScheduleType = .daily

    /// All secrets that the user has entered
    @Published var secrets: [Secret] = [] {
        didSet {
            saveItems()
            setupPublishers()
        }
    }

    /// Repeating, user-configured times to send notifications
    @Published var regularIntervalNotifications: [DateComponents] = [] {
        didSet {
            saveItems()
        }
    }
    
    /// Non-repeating, user-configured times to send notifications
    @Published var oneTimeNotifications: [DateComponents] = [] {
        didSet {
            saveItems()
        }
    }
    
    /// Categories for spaced repetition
    @Published var spacedRepetitionCategories: [SpacedRepetitionCategory] = [
        SpacedRepetitionCategory(name: "Daily", description: "", duration: 60 * 60 * 24),
        SpacedRepetitionCategory(name: "Every 3 days", description: "", duration: 60 * 60 * 24 * 3),
        SpacedRepetitionCategory(name: "Weekly", description: "", duration: 60 * 60 * 24 * 7),
        SpacedRepetitionCategory(name: "Every 2 weeks", description: "", duration: 60 * 60 * 24 * 7 * 2),
        SpacedRepetitionCategory(name: "Monthly", description: "", duration: 60 * 60 * 24 * 31),
    ] {
        didSet {
            saveItems()
            setupPublishers()
        }
    }
    
    /// We listen to changes to UserDefaults using NotificationManager
    /// Keep track of cancellables from NotificationManager here
    var cancellables: [ObjectIdentifier : AnyCancellable] = [:]
    /// It's easier to keep track of cancellables for regularIntervalsNotifications and oneTimeNotifications in separate arrays
    private var regularIntervalsNotificationsCancellables = Set<AnyCancellable>()
    private var oneTimeNotificationsCancellables = Set<AnyCancellable>()

    
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
        
        // These subscritions handle making the change in the Notification Center when we change entries
        // We store these in the cancellables property, so they are valid for the lifetime of the SecretsViewModel.
        // ([weak self] prevents a memory leak with automatic reference counting.)
        // These are passed by value so we can just use the simpler @Published and don't need to deal with them in setupPublishers()
        $regularIntervalNotifications
            .sink { [weak self] _ in
                appLogger.debug("SecretsViewModel $regularIntervalEntries .sink: noticed change, reregistering...")
                self?.reregisterAllNotifications()
            }
            .store(in: &regularIntervalsNotificationsCancellables)
        $oneTimeNotifications
            .sink { [weak self] _ in
                appLogger.debug("SecretsViewModel $oneTimeEntries .sink: noticed change, reregistering...")
                self?.reregisterAllNotifications()
            }
            .store(in: &oneTimeNotificationsCancellables)


        loadItems()
        setupPublishers()
    }
    
    /// Set a publisher for each observable.
    /// Whenever any items in the secrets or spacedRepetitionCategories changes, it triggers saveItems().
    ///
    /// Note the difference between the @Published property wrapper and what we do here.
    /// @Published will allow observation of any changes to the property itself,
    /// and we set @Published on all of the arrays we want to be observable.
    /// So far so good.
    /// However, for properties which are arrays, when an item IN the array mutates without mutating the array itself,
    /// @Published does not see this change.
    ///
    /// Structs are passed by value.
    /// For arrays of value types like structs,
    /// changes to any item in the array results in a new copy of the array.
    /// In this case, @Published sees the change, and we have nothing to do here.
    /// That's why this function doesn't need to do anything with our regularIntervalNotifications or oneTimeNotifications properties.
    ///
    /// However, class instances are passed by reference.
    /// For arrays of reference types like class instances,
    /// mutation of an item in the array can be done in place, without making a new copy of the array,
    /// which means that @Published cannot see that there was a change.
    /// Therefore, this function needs to iterate through each class instance in our secrets and spacedRepetitionCategories properties,
    /// and set up publishers on each instance individually in order to be notified when they are changed.
    ///
    /// We keep track of the cancellables so that we can throw away publishers for items we no longer need.
    /// When an item is added or deleted from the array of reference types with .addX or .removeX,
    /// we handle the publishers and cancellables there.
    /// This function handles loading new data, such as initialization time or if we swap to demo mode.
    ///
    /// Warnings:
    /// - If a reference type is replaced with a totally new instance, we will not detect it
    /// - If an array containing reference types is modified directly rather than through .addX or .removeX, we will not detect the change
    private func setupPublishers() {
        // Cancel any existing publishers
        cancellables.forEach { $0.value.cancel() }
        cancellables.removeAll()

        secrets.forEach { secret in
            let secretCancellable = secret.objectWillChange
                .sink { [weak self] _ in
                    self?.saveItems()
                }
            cancellables[ObjectIdentifier(secret)] = secretCancellable
        }
        
        spacedRepetitionCategories.forEach { category in
            let categoryCancellable = category.objectWillChange
                .sink { [weak self] _ in
                    self?.saveItems()
                }
            cancellables[ObjectIdentifier(category)] = categoryCancellable
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
    
    func addSecret(_ secret: Secret) {
        secrets.append(secret)
        let cancellable = secret.objectWillChange
            .sink { [weak self] _ in
                self?.saveItems()
            }
        cancellables[ObjectIdentifier(secret)] = cancellable
    }

    func removeSecret(_ secret: Secret) {
        if let index = secrets.firstIndex(of: secret) {
            secrets.remove(at: index)
            cancellables[ObjectIdentifier(secret)]?.cancel()
            cancellables[ObjectIdentifier(secret)] = nil
        }
    }
    
    func addSpacedRepCategory(_ category: SpacedRepetitionCategory) {
        spacedRepetitionCategories.append(category)
        let cancellable = category.objectWillChange
            .sink { [weak self] _ in
                self?.saveItems()
            }
        cancellables[ObjectIdentifier(category)] = cancellable
    }

    func removeSpacedRepCategory(_ category: SpacedRepetitionCategory) {
        if let index = spacedRepetitionCategories.firstIndex(of: category) {
            spacedRepetitionCategories.remove(at: index)
            cancellables[ObjectIdentifier(category)]?.cancel()
            cancellables[ObjectIdentifier(category)] = nil
        }
    }
    
    
    // MARK: - One Time Notifications
    
    func addOneTimeNotification(_ dateComponents: DateComponents, completion: @escaping () -> Void) {
        oneTimeNotifications.append(dateComponents)
        saveItems()
        reregisterAllNotifications()
        completion()
    }

    func deleteOneTimeNotification(_ dateComponents: DateComponents) {
        if let index = oneTimeNotifications.firstIndex(of: dateComponents) {
            oneTimeNotifications.remove(at: index)
            saveItems()
            reregisterAllNotifications()
        }
    }
    
    // MARK: - Regular Interval Notifications
    
    func addRegularIntervalNotification(_ dateComponents: DateComponents, completion: @escaping () -> Void) {
        regularIntervalNotifications.append(dateComponents)
        saveItems()
        reregisterAllNotifications()
        completion()
    }

    func deleteRegularIntervalNotification(_ dateComponents: DateComponents) {
        if let index = regularIntervalNotifications.firstIndex(of: dateComponents) {
            regularIntervalNotifications.remove(at: index)
            saveItems()
            reregisterAllNotifications()
        }
    }
    
    func saveItems() {
        let collection = SecretCollection(
            secrets: secrets,
            regularIntervalNotifications: regularIntervalNotifications,
            oneTimeNotifications: oneTimeNotifications,
            spacedRepetitionCategories: spacedRepetitionCategories
        )
        dataLoader.save(collection: collection)
    }
    
    func loadItems() {
        let collection = dataLoader.load()
        secrets = collection.secrets
        regularIntervalNotifications = collection.regularIntervalNotifications
        oneTimeNotifications = collection.oneTimeNotifications
        spacedRepetitionCategories = collection.spacedRepetitionCategories
        setupPublishers()
    }
    
    func deleteAllData() {
        secrets = []
        regularIntervalNotifications = []
        oneTimeNotifications = []
        spacedRepetitionCategories = []
        
        dataLoader.deleteAllData()
        setupPublishers()
        
        reregisterAllNotifications()
    }
    
    /// Remove all notifications from the Notification Center for the app, and register all notifications in this view model.
    /// Uses the view model as the source of truth.
    func reregisterAllNotifications() {
        // Don't do anything if the user hasn't granted us notification permissions
        NotificationManager.shared.requestPermission { granted in
            if granted {
                appLogger.debug("reregisterAllNotifications: granted permission to notify, registering...")
                NotificationManager.shared.removeNotifications()
                
                for schedule in self.regularIntervalNotifications {
                    addQuizNotification(components: schedule, prefix: "RegularIntervals-", repeats: true)
                }
                
                for components in self.oneTimeNotifications {
                    addQuizNotification(components: components, prefix: "OneTime-", repeats: false)
                }
                
                // TODO: configure spaced repetition notifications here!!
            } else {
                appLogger.debug("reregisterAllNotifications: not granted permission to notify, nothing we can do")
            }
        }
    }

}
