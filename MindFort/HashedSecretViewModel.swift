//
//  HashedSecretViewModel.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation

protocol DataLoader {
    func load() -> [HashedSecret]
    func save(secrets: [HashedSecret]) -> ()
}

class PlistDataLoader: DataLoader {
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    
    init() {}
    
    private var plistURL: URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }
        return documentsURL.appendingPathComponent("HashedSecrets.plist")
    }
    

    
    func load() -> [HashedSecret] {
        do {
            let data = try Data(contentsOf: plistURL)
            let secrets = try decoder.decode([HashedSecret].self, from: data)
            print("When loading, found secrets: \(secrets)")
            return secrets
        } catch {
            print("Error loading items: \(error)")
            return []
        }
    }
    
    func save(secrets: [HashedSecret]) {
        do {
            let data = try encoder.encode(secrets)
            try data.write(to: plistURL)
        } catch {
            print("Error saving items: \(error)")
        }
    }
}

class PreviewDataLoader: DataLoader {
    var secrets: [HashedSecret]
    init(secrets: [HashedSecret]) {
        self.secrets = secrets
    }
    func load() -> [HashedSecret] {
        return secrets
    }
    func save(secrets secretsIn: [HashedSecret]) {
        secrets = secretsIn
    }
}

class HashedSecretViewModel: ObservableObject {
    @Published var secrets: [HashedSecret] = []
    
    private var dataLoader: DataLoader
    
    init(dataLoader: DataLoader) {
        self.dataLoader = dataLoader
    }
    
    func addItem(_ item: HashedSecret) {
        secrets.append(item)
        saveItems()
    }
    
    func deleteItem(_ item: HashedSecret) {
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
