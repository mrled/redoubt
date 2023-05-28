//
//  HashedSecretViewModel.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation

class HashedSecretViewModel: ObservableObject {
    @Published var secrets: [HashedSecret] = []
    
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    
    private var plistURL: URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }
        return documentsURL.appendingPathComponent("HashedSecrets.plist")
    }
    
    func addItem(_ item: HashedSecret) {
        secrets.append(item)
        saveItems()
    }
    
    func saveItems() {
        do {
            let data = try encoder.encode(secrets)
            try data.write(to: plistURL)
        } catch {
            print("Error saving items: \(error)")
        }
    }
    
    func loadItems() {
        do {
            let data = try Data(contentsOf: plistURL)
            secrets = try decoder.decode([HashedSecret].self, from: data)
            print("When loading, found secrets: \(secrets)")
        } catch {
            print("Error loading items: \(error)")
        }
    }
}
