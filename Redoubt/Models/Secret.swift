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


/// Calculate a value for the .id property of a Secret object
func calculateSecretId(name: String, digest: String) throws -> UUID {
    guard let data = (name + digest).data(using: .utf8) else {
        throw SecretParsingError.invalidInputValue
    }
    return md5UUID(data: data)
}




/// A hash of a secret, stored securely.
///
/// Usable with the id, name, digest, and digestType properties
///
/// Only init(name:plaintext:), update(newPlaintext:), and validate(plaintextIn:) need to be updated if our hashing algorithm changes.
///
/// Equatable (the == operator) is only if the id matches; this struct can't tell if two underlying plaintexts are the same,
/// mostly because it doesn't necessarily know what they are.
class Secret: Identifiable, ObservableObject, Codable, Equatable {

    /// The id field should be composed of the name and hashed value of a secret --
    /// requiring the name means we can have two secrets with different plaintexts but the same name.
    /// Note that this should NOT be a computed property -- we don't want the ID to change if the user updates the name or plaintext.
    ///
    /// It's important that the UUID not change, so we cannot just do UUID() !
    /// If it changes, views will get new copies of the same data, and iterating won't work.
    @Published var id: UUID

    /// The user-visible name for the secret
    @Published var name: String
    
    /// The digest is a String because it's easier for Codable and calculateId, and it's what you get natively from Argon2.
    /// For raw hash like SHA512, just use a string encoding like base64 or hex.
    @Published var digest: String
    
    @Published var digestType: SupportedDigestType
    
    @Published var lastQuizzed: Date?

    @Published var lastQuizPassed: Bool = false

    @Published var consecutiveSuccesses: Int = 0

    @Published var spacedRepetitionCategory: String?

    @Published var plaintext: String?
    
    private let sodium = Sodium()
    
    enum CodingKeys: String, CodingKey {
        case name, digest, digestType, lastQuizzed, lastQuizPassed, consecutiveSuccesses, spacedRepetitionCategory
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(digest, forKey: .digest)
        try container.encode(digestType, forKey: .digestType)
        try container.encode(lastQuizzed, forKey: .lastQuizzed)
        try container.encode(lastQuizPassed, forKey: .lastQuizPassed)
        try container.encode(consecutiveSuccesses, forKey: .consecutiveSuccesses)
        try container.encode(spacedRepetitionCategory, forKey: .spacedRepetitionCategory)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedName = try container.decode(String.self, forKey: .name)
        name = decodedName
        let digestTypeString = try container.decode(String.self, forKey: .digestType)
        digestType = SupportedDigestType(rawValue: digestTypeString)!
        let decodedDigest = try container.decode(String.self, forKey: .digest)
        digest = decodedDigest
        id = try calculateSecretId(name: decodedName, digest: decodedDigest)
        lastQuizzed = try container.decodeIfPresent(Date.self, forKey: .lastQuizzed)
        lastQuizPassed = try container.decodeIfPresent(Bool.self, forKey: .lastQuizPassed) ?? false
        consecutiveSuccesses = try container.decodeIfPresent(Int.self, forKey: .consecutiveSuccesses) ?? 0
        spacedRepetitionCategory = try container.decodeIfPresent(String.self, forKey: .spacedRepetitionCategory)
    }
    
    /// Create a Secret by value
    /// Hash the value and return only the computed hash, not the secret
    init(name: String, plaintext: String, spacedRepetitionCategory: String? = nil) throws {
        self.name = name
        self.plaintext = plaintext
        self.spacedRepetitionCategory = spacedRepetitionCategory
        digestType = .Argon2
        guard let newDigest = sodium.pwHash.str(passwd: Array(plaintext.utf8), opsLimit: sodium.pwHash.OpsLimitInteractive, memLimit: sodium.pwHash.MemLimitInteractive) else {
            throw SecretParsingError.invalidInputValue
        }
        digest = newDigest
        id = try calculateSecretId(name: name, digest: newDigest)
        print("Creating new Argon2 secret")
    }
    
    /// Update the hashed value with a new plaintext value, and the current best practice digest type
    func update(newPlaintext: String) throws {
        digestType = .Argon2
        guard let newDigest = sodium.pwHash.str(passwd: Array(newPlaintext.utf8), opsLimit: sodium.pwHash.OpsLimitInteractive, memLimit: sodium.pwHash.MemLimitInteractive) else {
            throw SecretParsingError.invalidInputValue
        }
        digest = newDigest
    }

    /// Verify that the input plaintext matches this secret's stored plaintext
    /// This might not be a simple string comparison, eg salts.
    /// Update .lastQuizzed, .lastQuizPassed, and .consecutiveSuccesses
    /// If validation is successful, make sure we are using the best digest type and re-hash if not
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

        lastQuizzed = Date()

        // Update quiz tracking based on validation result
        if validated {
            consecutiveSuccesses += 1
            lastQuizPassed = true
        } else {
            consecutiveSuccesses = 0
            lastQuizPassed = false
        }

        // If we validate, make sure we are using the latest and most secure storage mechanism.
        if validated && (digestType != BestDigestType) {
            let logName = name
            let logId = id
            do {
                try update(newPlaintext: plaintextIn)
            } catch {
                appLogger.error("Could not update plaintext of Secret '\(logName)' (\(logId)) to \(BestDigestType.rawValue): \(error)")
            }
        }

        return validated
    }
    
    static func == (left: Secret, right: Secret) -> Bool {
        return left.id == right.id
    }
}
