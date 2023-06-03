//
//  SecretListViewModel.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation

/// Load secret data from somewhere and hand it to the view model
protocol DataLoader {
    func load() -> [Secret]
    func save(secrets: [Secret]) -> ()
    func deleteAllData() -> ()
}

/// Load secret data from a property list in the app's documents directory
class SecretsVmDataLoaderFromPlist: DataLoader {
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    
    init() {}
    
    func load() -> [Secret] {
        do {
            let data = try Data(contentsOf: MFFStorage().secretsPlist)
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
            try data.write(to: MFFStorage().secretsPlist)
        } catch {
            print("Error saving items: \(error)")
        }
    }
    
    func deleteAllData() {
        do {
            try FileManager.default.removeItem(at: MFFStorage().secretsPlist)
        } catch {
            print("Error deleting \(MFFStorage().secretsPlist): \(error)")
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
    @Published var secrets: [Secret] = []
    
    private var dataLoader: DataLoader
    
    init(dataLoader: DataLoader) {
        self.dataLoader = dataLoader
        loadItems()
    }
    
    func addItem(_ item: Secret) {
        secrets.append(item)
        saveItems()
    }
    
    func deleteItem(_ item: Secret) {
        if let index = secrets.firstIndex(of: item) {
            secrets.remove(at: index)
            saveItems()
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
