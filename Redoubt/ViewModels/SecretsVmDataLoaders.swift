import Foundation


/// Load secret data from somewhere and hand it to the view model
protocol SecretsVmDataLoader {
    func load() -> SecretCollection
    func save(collection: SecretCollection) -> ()
    func deleteAllData() -> ()
}

/// Load secret data from a property list in the app's documents directory
/// TODO: rename this
class SecretsVmDataLoaderFromPlist: SecretsVmDataLoader {
    var collectionPlist: URL
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    
    init(collectionPlist: URL) {
        self.collectionPlist = collectionPlist
    }
    
    func load() -> SecretCollection {
        do {
            let data = try Data(contentsOf: collectionPlist)
            let collection = try decoder.decode(SecretCollection.self, from: data)
//            print("When loading, found secret collection: \(collection)")
            return collection
        } catch {
            print("Error loading items: \(error)")
            return SecretCollection(secrets: [], regularIntervalNotifications: [], oneTimeNotifications: [])
        }
    }
    
    func save(collection: SecretCollection) {
        do {
            let data = try encoder.encode(collection)
            try data.write(to: collectionPlist)
        } catch {
            print("Error saving items: \(error)")
        }
    }
    
    func deleteAllData() {
        do {
            try FileManager.default.removeItem(at: collectionPlist)
        } catch {
            print("Error deleting \(collectionPlist): \(error)")
        }
    }
}

/// "Load" data that is passed in from a preview function
class SecretsVmDataLoaderFromArray: SecretsVmDataLoader {
    var collection: SecretCollection
    init(_ collection: SecretCollection) {
        self.collection = collection
    }
    func load() -> SecretCollection {
        return collection
    }
    func save(collection: SecretCollection) {
        self.collection = collection
    }
    func deleteAllData() {
        collection = SecretCollection(secrets: [], regularIntervalNotifications: [], oneTimeNotifications: [])
    }
}
