//
//  HashedSecret.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation
import CryptoKit

enum HashedSecretError: Error {
    case invalidData
}

struct HashedSecret: Identifiable {
    let id = UUID()
    var name: String
    var digest: any Digest
    var h4xx0rcode: String {
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Create a HashedSecret by value
    /// Hash the value and return only the computed hash, not the secret
    static func fromValue(_ value: String, name: String) -> Result<HashedSecret, HashedSecretError> {
        guard let data = value.data(using: .utf8) else {
            return .failure(.invalidData)
        }
        let digest = SHA512.hash(data: data)
        let secret = HashedSecret(name: name, digest: digest)
        return .success(secret)
    }
}
