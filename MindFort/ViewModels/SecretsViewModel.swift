//
//  SecretListViewModel.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation
import Combine

/// Load secret data from somewhere and hand it to the view model
protocol DataLoader {
    func load() -> [Secret]
    func save(secrets: [Secret]) -> ()
    func deleteAllData() -> ()
}

/// Load secret data from a property list in the app's documents directory
class SecretsVmDataLoaderFromPlist: DataLoader {
    var secretsPlist: URL
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    
    init(secretsPlist: URL) {
        self.secretsPlist = secretsPlist
    }
    
    func load() -> [Secret] {
        do {
            let data = try Data(contentsOf: secretsPlist)
            let secrets = try decoder.decode([Secret].self, from: data)
            print("When loading, found secrets: \(secrets)")
            return secrets
        } catch {
            print("Error loading items: \(error)")
            return []
        }
    }
    
    func save(secrets: [Secret]) {
        do {
            let data = try encoder.encode(secrets)
            try data.write(to: secretsPlist)
        } catch {
            print("Error saving items: \(error)")
        }
    }
    
    func deleteAllData() {
        do {
            try FileManager.default.removeItem(at: secretsPlist)
        } catch {
            print("Error deleting \(secretsPlist): \(error)")
        }
    }
}

/// "Load" data that is passed in from a preview function
class SecretsVmDataLoaderFromArray: DataLoader {
    var secrets: [Secret]
    init(_ secretsIn: [Secret]) {
        self.secrets = secretsIn
    }
    func load() -> [Secret] {
        return secrets
    }
    func save(secrets secretsIn: [Secret]) {
        secrets = secretsIn
    }
    func deleteAllData() {
        secrets = []
    }
}

class SecretsViewModel: ObservableObject {
    @Published var secrets: [Secret] = [] {
        didSet {
            saveItems()
            setupPublishers()
        }
    }

    private var cancellables = Set<AnyCancellable>()
    
    private var dataLoader: DataLoader
    private var inDemoMode: Bool
    private var userDefautlsObserver: Any?
    
    init(dataLoader: DataLoader? = nil) {
//        self.dataLoader = dataLoader
        
        // Why use UserDefaults here, which requires adding the Observer below,
        // when AppStorage is supposed to handle observability for us?
        // Because AppStorage can only do that automatically in a SwiftUI View,
        // and was really only intended to be used in View code.
        inDemoMode = UserDefaults.standard.bool(forKey: "demoMode")
        
        let secretsPlist = inDemoMode ? MFFStorage().secretsDemoPlist : MFFStorage().secretsUserPlist
        
        self.dataLoader = dataLoader ?? SecretsVmDataLoaderFromPlist(secretsPlist: secretsPlist)
        
        // This listens for changes on ANY UserDefaults key, lol
        // TODO: replace this with something that only listens to the specific key we care about
        userDefautlsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            // We don't get the new value for demoMode
            self?.userDefaultsDidChange()
        }

        loadItems()
        setupPublishers()
    }
    
    /// Set a publisher for each secret in our .secrets array.
    /// Whenever any secret changes, it triggers saveItems().
    private func setupPublishers() {
        // Cancel any existing publishers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Create new publishers for each secret
        secrets.forEach { secret in
            secret.objectWillChange
                .sink { [weak self] _ in
                    self?.saveItems()
                }
                .store(in: &cancellables)
        }
    }
    
    func userDefaultsDidChange() {
        let oldDemoMode = inDemoMode
        inDemoMode = UserDefaults.standard.bool(forKey: "demoMode")
        if inDemoMode != oldDemoMode {
            let secretsPlist = inDemoMode ? MFFStorage().secretsDemoPlist : MFFStorage().secretsUserPlist
            dataLoader = SecretsVmDataLoaderFromPlist(secretsPlist: secretsPlist)
            if inDemoMode {
                // If we are transitioning to demo mode from regular mode,
                // we want a clean slate with a default list of passwords
                dataLoader.save(secrets: getDemoModePasswords())
            }
            loadItems()
        }
    }
    
    // TODO: now that we have the didSet on the secrets array, we no longer have to call saveItems() here - change all callers to just modify the .secrets array
    func addItem(_ item: Secret) {
        secrets.append(item)
    }
    
    func deleteItem(_ item: Secret) {
        if let index = secrets.firstIndex(of: item) {
            secrets.remove(at: index)
        }
    }
    
    func saveItems() {
        dataLoader.save(secrets: secrets)
    }
    
    func loadItems() {
        secrets = dataLoader.load()
    }
    
    func deleteAllData() {
        dataLoader.deleteAllData()
    }
}
