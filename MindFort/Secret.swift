//
//  Secret.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation
import CryptoKit
import CommonCrypto

enum SecretParsingError: Error {
    case invalidInputValue
    case invalidDictValue
}


enum SupportedDigestType: String, Codable {
    case SHA512 = "SHA512"
}


func sha512(data: Data) -> Data {
    let rawDigest = SHA512.hash(data: data)
    let digestData = Data(rawDigest.withUnsafeBytes { pointer in
        return Data(bytes: pointer.baseAddress!, count: SHA512.Digest.byteCount)
    })
    return digestData
}


/// NOTE: we're just using this for UUIDs! Nothing else!
func md5Hash(of data: Data) -> Data {
    var hash = Data(count: Int(CC_MD5_DIGEST_LENGTH))
    data.withUnsafeBytes { dataBytes in
        hash.withUnsafeMutableBytes { hashBytes in
            _ = CC_MD5(dataBytes.baseAddress, CC_LONG(data.count), hashBytes.bindMemory(to: UInt8.self).baseAddress)
        }
    }
    return hash
}


func md5UUID(data: Data) -> UUID {
    let hashedData = md5Hash(of: data)
    let uuid = UUID(uuid: hashedData.withUnsafeBytes { $0.load(as: uuid_t.self) })
    return uuid
}


func sha512(string: String) throws -> Data  {
    guard let stringData = string.data(using: .utf8) else {
        throw SecretParsingError.invalidInputValue
    }
    return sha512(data: stringData)
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

/// Return the input string in groups of characters and lines
func groupCharacters(string: String, perGroup: Int = 4, perLine: Int = 8) -> String {
    var result = ""
    var count = 0
    
    for (index, char) in string.enumerated() {
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

/// Given a SHA512 hash binary value, return a list of number groups
func prettyHashBlock(digest: Data, perGroup: Int = 4, perLine: Int = 8) -> String {
    let hexString = digest.map { String(format: "%02x", $0) }.joined()
    return groupCharacters(string: hexString, perGroup: perGroup, perLine: perLine)
}

func placeholderHashBlock(perGroup: Int = 4, perLine: Int = 8) -> String {
    let placeholderStrings = [
        "dead", "beef", "babe", "cafe",
        "dead", "beef", "babe", "cafe",
        "dead", "beef", "babe", "cafe",
        "dead", "beef", "babe", "cafe",
        "dead", "beef", "babe", "cafe",
        "dead", "beef", "babe", "cafe",
        "dead", "beef", "babe", "cafe",
        "dead", "beef", "babe", "cafe",
    ]
    let placeholderString = placeholderStrings.joined(separator: "")
    return groupCharacters(string: placeholderString, perGroup: perGroup, perLine: perLine)
}

let easterEggPasswords: Dictionary<String, [String]> = [
    "hunter2": [
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
    ],
    "love": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "sex": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "secret": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "god": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "swordfish": [
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
    ],
    "correct horse battery staple": [
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
    ],
    "penis": [
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
    ]
]
