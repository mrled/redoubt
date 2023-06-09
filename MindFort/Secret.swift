//
//  Secret.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation
import CryptoKit

import Sodium


enum SecretParsingError: Error {
    case invalidInputValue
    case invalidDictValue
}


enum SupportedDigestType: String, Codable {
    case SHA512 = "SHA512"
    case Argon2 = "Argon2"
}


let BestDigestType: SupportedDigestType = .Argon2


/// A hash of a secret, stored securely.
///
/// Usable with the id, name, digest, and digestType properties
///
/// Only init(name:plaintext:), update(newPlaintext:), and validate(plaintextIn:) need to be updated if our hashing algorithm changes.
///
/// Equatable (the == operator) is only if the id matches; this struct can't tell if two underlying plaintexts are the same,
/// mostly because it doesn't necessarily know what they are.
///
/// TODO: Update to the BestDigestType during update() or successful validate()
struct Secret: Identifiable, Codable, Equatable {

    /// The id field should be composed of the name and hashed value of a secret --
    /// requiring the name means we can have two secrets with different plaintexts but the same name.
    /// Note that this should NOT be a computed property -- we don't want the ID to change if the user updates the name or plaintext.
    ///
    /// It's important that the UUID not change, so we cannot just do UUID() !
    /// If it changes, views will get new copies of the same data, and iterating won't work.
    var id: UUID

    /// The user-visible name for the secret
    var name: String
    
    /// The digest is a String because it's easier for Codable and calculateId, and it's what you get natively from Argon2.
    /// For raw hash like SHA512, just use a string encoding like base64 or hex.
    var digest: String
    
    var digestType: SupportedDigestType
    var plaintext: String?
    
    private let sodium = Sodium()
    
    enum CodingKeys: String, CodingKey {
        case name, digest, digestType
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(digest, forKey: .digest)
        try container.encode(digestType, forKey: .digestType)
    }
    
    /// The .id will be the raw data behind the .name string plus the .digest data
    /// This means you can't have two Secret instances in the same list with the same name and digest.
    static private func calculateId(_ nameIn: String, _ digestIn: String) throws -> UUID {
        guard let data = (nameIn + digestIn).data(using: .utf8) else {
            throw SecretParsingError.invalidInputValue
        }
        return md5UUID(data: data)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let digestTypeString = try container.decode(String.self, forKey: .digestType)
        digestType = SupportedDigestType(rawValue: digestTypeString)!
        digest = try container.decode(String.self, forKey: .digest)
        id = try Secret.calculateId(name, digest)
    }
    
    /// Create a Secret by value
    /// Hash the value and return only the computed hash, not the secret
    init(name nameIn: String, plaintext plaintextIn: String) throws {
        name = nameIn
        plaintext = plaintextIn
        digestType = .Argon2
        guard let newDigest = sodium.pwHash.str(passwd: Array(plaintextIn.utf8), opsLimit: sodium.pwHash.OpsLimitInteractive, memLimit: sodium.pwHash.MemLimitInteractive) else {
            throw SecretParsingError.invalidInputValue
        }
        digest = newDigest
        id = try Secret.calculateId(name, digest)
        print("Creating new Argon2 secret")
    }
    
    /// Update the hashed value with a new plaintext value, and the current best practice digest type
    /// TODO: this doesn't work in a struct with our view hierarchy, might need to make this a class that implements ObservedObject
//    mutating func update(newPlaintext: String) throws {
//        digestType = .Argon2
//        guard let newDigest = sodium.pwHash.str(passwd: Array(newPlaintext.utf8), opsLimit: sodium.pwHash.OpsLimitInteractive, memLimit: sodium.pwHash.MemLimitInteractive) else {
//            throw SecretParsingError.invalidInputValue
//        }
//        digest = newDigest
//    }

    /// Verify that the input plaintext matches this secret's stored plaintext
    /// This might not be a simple string comparison, eg salts.
    /// TODO: we can't update on validation until we can have mutations, which might require making this a class that implements ObservedObject
//    mutating func validate(plaintextIn: String) -> Bool {
    func validate(plaintextIn: String) -> Bool {
        guard let inputData = plaintextIn.data(using: .utf8) else {
            return false
        }
        var validated = false
        
        switch digestType {
        case .SHA512:
            let newDigest = sha512(data: inputData)
            validated = Data(base64Encoded: digest) == newDigest
        case .Argon2:
            validated = sodium.pwHash.strVerify(hash: digest, passwd: Array(plaintextIn.utf8))
        }
        
        // If we validate, make sure we are using the latest and most secure storage mechanism.
//        if validated && (digestType != BestDigestType) {
//            let logName = name
//            let logId = id
//            do {
//                try update(newPlaintext: plaintextIn)
//            } catch {
//                appLogger.error("Could not update plaintext of Secret '\(logName)' (\(logId)) to \(BestDigestType.rawValue): \(error)")
//            }
//        }
        
        return validated
    }
    
    static func == (left: Secret, right: Secret) -> Bool {
        return left.id == right.id
    }
}
