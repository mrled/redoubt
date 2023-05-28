//
//  HashedSecret.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation
import CryptoKit

enum HashedSecretError: Error {
    case invalidInputValue
    case invalidDictValue
}


enum SupportedDigestType: String, Codable {
    case SHA512 = "SHA512"
}


struct HashedSecret: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var digest: Data
    var digestType: SupportedDigestType
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
    }
    
    /// Create a HashedSecret by value
    /// Hash the value and return only the computed hash, not the secret
    init(name nameIn: String, value: String) throws {
        name = nameIn
        guard let valueData = value.data(using: .utf8) else {
            throw HashedSecretError.invalidInputValue
        }
        let rawDigest = SHA512.hash(data: valueData)
        let digestData = Data(rawDigest.withUnsafeBytes { pointer in
            return Data(bytes: pointer.baseAddress!, count: SHA512.Digest.byteCount)
        })
        digest = digestData
        digestType = .SHA512
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
    
    static func == (left: HashedSecret, right: HashedSecret) -> Bool {
        return left.id == right.id
    }
}


/// Given a SHA512 hash binary value, return a list of number groups
func prettyHashBlock(digest: Data, perGroup: Int = 4, perLine: Int = 8) -> String {
    let hexString = digest.map { String(format: "%02x", $0) }.joined()

    var result = ""
    var count = 0
    
    for (index, char) in hexString.enumerated() {
        result.append(char)
        
        if (index + 1) % perGroup == 0 {
            result.append(" ")
            count += 1
        }
        
        if count == perLine {
            result.append("\n")
            count = 0
        }
    }
    return result
}
