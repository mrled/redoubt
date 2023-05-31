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
}

/// Load secret data from a property list in the app's documents directory
class PlistDataLoader: DataLoader {
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    
    init() {}
    
    private var plistURL: URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }
        return documentsURL.appendingPathComponent("Secrets.plist")
    }
    
    func load() -> [Secret] {
        do {
            let data = try Data(contentsOf: plistURL)
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
            try data.write(to: plistURL)
        } catch {
            print("Error saving items: \(error)")
        }
    }
}

/// "Load" data that is passed in from a preview function
class PreviewDataLoader: DataLoader {
    var secrets: [Secret]
    init(secrets: [Secret]) {
        self.secrets = secrets
    }
    func load() -> [Secret] {
        return secrets
    }
    func save(secrets secretsIn: [Secret]) {
        secrets = secretsIn
    }
}

class SecretsViewModel: ObservableObject {
    @Published var secrets: [Secret] = []
    
    private var dataLoader: DataLoader
    
    init(dataLoader: DataLoader) {
        self.dataLoader = dataLoader
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
}
