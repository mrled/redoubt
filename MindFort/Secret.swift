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
    let id = UUID()
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
    
    /// Create a Secret by value
    /// Hash the value and return only the computed hash, not the secret
    init(name nameIn: String, value valueIn: String) throws {
        name = nameIn
        value = valueIn
        guard let valueData = valueIn.data(using: .utf8) else {
            throw SecretParsingError.invalidInputValue
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
