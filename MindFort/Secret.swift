//
//  Secret.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation
import CryptoKit

enum SecretParsingError: Error {
    case invalidInputValue
    case invalidDictValue
}


enum SupportedDigestType: String, Codable {
    case SHA512 = "SHA512"
}


struct Secret: Identifiable, Codable, Equatable {

    /// It's important that the UUID not change, so we cannot just do UUID() !
    /// If it changes, views will get new copies of the same data, and iterating won't work.
    var id: UUID

    var name: String
    var digest: Data
    var digestType: SupportedDigestType
    var value: String?
    
    var h4xx0rcode: String {
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    enum CodingKeys: String, CodingKey {
        case name, digest, digestType
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        let digestString = digest.base64EncodedString()
        try container.encode(digestString, forKey: .digest)
        try container.encode(digestType, forKey: .digestType)
    }
    
    /// The .id will be the raw data behind the .name string plus the .digest data
    /// This means you can't have two Secret instances in the same list with the same name and digest
    /// (although once I move to some kind of salted thing that will change)
    private static func calculateId(name: String, digest: Data) throws -> UUID {
        guard let nameData = name.data(using: .utf8) else {
            throw SecretParsingError.invalidInputValue
        }
        return md5UUID(data: nameData + digest)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let digestTypeString = try container.decode(String.self, forKey: .digestType)
        digestType = SupportedDigestType(rawValue: digestTypeString)!
        let digestString = try container.decode(String.self, forKey: .digest)
        guard let digestData = Data(base64Encoded: digestString) else {
            throw DecodingError.dataCorruptedError(forKey: .digest, in: container, debugDescription: "Expected base64 encoded string")
        }
        digest = digestData
        id = try Secret.calculateId(name: name, digest: digest)
    }
    
    /// Create a Secret by value
    /// Hash the value and return only the computed hash, not the secret
    init(name nameIn: String, value valueIn: String) throws {
        name = nameIn
        value = valueIn
        try digest = sha512(string: valueIn)
        digestType = .SHA512
        id = try Secret.calculateId(name: name, digest: digest)
    }
    
    func validate(input: String) -> Bool {
        guard let inputData = input.data(using: .utf8) else {
            return false
        }
        let rawDigest = SHA512.hash(data: inputData)
        let inputDigest = Data(rawDigest.withUnsafeBytes { pointer in
            return Data(bytes: pointer.baseAddress!, count: SHA512.Digest.byteCount)
        })
        return digest == inputDigest
    }
    
    static func == (left: Secret, right: Secret) -> Bool {
        return left.id == right.id
    }
}
