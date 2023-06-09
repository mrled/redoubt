//
//  Cryptography.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-07.
//

import Foundation
import CryptoKit
import CommonCrypto


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


/// This is the easiest way to get a Swift UUID from arbitrary data.
/// It's weak against collision attacks because lol md5 of course.
/// It's also not a valid UUID per the UUID specification.
/// What we want to use it for is the Identifiable protocol, and only that, so we're not worried about it.
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


