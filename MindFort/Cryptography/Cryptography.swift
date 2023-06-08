//
//  Cryptography.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-07.
//

import Foundation
import CryptoKit
import CommonCrypto
import CryptoSwift


enum CryptographyError: Error {
    case byteCopyError
}



/// Get a new array of random bytes
/// See also
/// - https://developer.apple.com/documentation/security/randomization_services
/// - https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
func getRandomBytes(length: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: 10)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    if status == errSecSuccess {
        return bytes
    } else {
        throw CryptographyError.byteCopyError
    }
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
 

/// Run the scrypt function but use MindFort defaults
///
/// Scrypt has tunable N, r, p parameters, to understand them, see https://words.filippo.io/the-scrypt-parameters/
/// We have chosen defaults from the Go scrypt implementation for interactive logins.
/// chosen in 2017: https://github.com/golang/go/issues/22082
/// still in place in 2023: https://cs.opensource.google/go/x/crypto/+/master:scrypt/scrypt.go;l=191
///
/// TODO: Consider raising these defaults, as some passwords might be protecting files or password databases.
/// The parameters are tuned to responsiveness for interactive logins, but if these passwords are for eg password databases,
/// the password database might use scrypt with higher values for these, as the tolerance for latency is higher.
///
/// We also specify a dkLen in these defaults.
/// dkLen is the output length... it is the Derived Key LENgh that Scrypt passes to PBKDF2.
/// It is used in PBKDF2 to get a key that is whatever size is necessary to use in the next step of the cryptographic pipeline.
/// For example, if you plan to use the derived key with an AES-256 cipher, you would specify a dkLen of 32 bytes (256 bits), because AES-256 requires a key of that length.
/// The tarsnap header format uses SHA256, which naturally also requires a dkLen of that size.
func scryptMfDefaults(password: String, salt: [UInt8]) throws -> [UInt8] {
    let passwordData: Array<UInt8> = Array(password.utf8)
    return try Scrypt(password: passwordData, salt: salt, dkLen: 32, N: 32768, r: 8, p: 1).calculate()
}


struct ScryptHash {
    let value: [UInt8]
    let salt: [UInt8]
    let N: UInt
    let r: UInt
    let p: UInt
    
    var valueHex: String {
        value.map { String(format: "%02x", $0) }.joined()
    }
    
    var saltHex: String {
        salt.map { String(format: "%02x", $0) }.joined()
    }
    
    /// See https://stackoverflow.com/a/40558471/868206
    /// Also described well in node-scrypt documentation: https://www.npmjs.com/package/scrypt#if-random-salts-are-used-why-do-all-resulting-kdfs-start-with-c2nyexb0-
    /// Note that to be perfectly compatible with the Tarsnap format, you must use 32 byte salts,
    /// but this implementation supports salts of any type.
    /// This implementation, like Tarsnap, does require a 32 byte dkLen,
    /// because it uses sha256 for HMAC, which requires a 32 byte key.
    func tarsnapHeader() throws -> String {
        // Create header
        var header = Data()

        // 6 bytes 'scrypt'
        header.append("scrypt".data(using: .utf8)!)

        // 10 bytes log2(N), r, p parameters
        // Assuming N, r, p are Int32 and stored in big-endian
        // N must be a power of 2, and log2 requires Doubles, so we do a Double conversion
        // log2 could return a non-integer if N is not a power of 2; no checking is done here
        var zeroByte = UInt8(0).bigEndian
        var bigEndianLog2N = UInt8(log2(Double(N))).bigEndian
        var bigEndianR = UInt32(r).bigEndian
        var bigEndianP = UInt32(p).bigEndian
        header.append(Data(bytes: &zeroByte, count: MemoryLayout<UInt8>.size))
        header.append(Data(bytes: &bigEndianLog2N, count: MemoryLayout<UInt8>.size))
        header.append(Data(bytes: &bigEndianR, count: MemoryLayout<UInt32>.size))
        header.append(Data(bytes: &bigEndianP, count: MemoryLayout<UInt32>.size))

        // 32 bytes salt
        header.append(Data(salt))

        // 16 bytes SHA256 checksum of bytes 0-47
        // Note that a SHA256 checksum is 32 bytes, and Tarsnap just uses the first 16 !!!
        // https://github.com/Tarsnap/scrypt/blob/master/FORMAT
        // Tarsnap has a 32 bit salt, always; we adjust to allow salts of any length
        //        let checksum = header.prefix(48).sha256()
        let checksum = header.prefix(header.count).sha256()
        header.append(Data(checksum.prefix(16)))

        // 32 bytes HMAC hash of bytes 0-63 (using scrypt hash as key)
        // Note that the Tarsnap header uses sha256 again here for the HMAC,
        // and that's probably a wise move for consistency and reasoning about the code,
        // but the previous function choice is not related to function choice here.
        // Again, adapt to salt of any length
        let hmac = try HMAC(key: value, variant: .sha256).authenticate(Array(header.prefix(64)))
//        let hmac = try HMAC(key: value, variant: .sha2(.sha256)).authenticate(Array(header.prefix(header.count)))
        header.append(Data(hmac))
        
        // Base64 encode the header
        let base64Header = header.base64EncodedString()

        return base64Header
    }
}


struct ScryptHashWIP {
    let value: [UInt8]
    let salt: [UInt8]
    let N: UInt
    let r: UInt
    let p: UInt
    
    func tarsnapHeader() throws -> String {
        // Create header
        var header = Data()

        // 6 bytes 'scrypt'
        header.append("scrypt".data(using: .utf8)!)

        // 10 bytes zero, log2(N), r, p parameters
        // Assuming N, r, p are Int32 and stored in big-endian
        var zeroByte = UInt8(0).bigEndian
        var bigEndianLog2N = UInt8(log2(Double(N))).bigEndian
        var bigEndianR = UInt32(r).bigEndian
        var bigEndianP = UInt32(p).bigEndian
        header.append(Data(bytes: &zeroByte, count: MemoryLayout<UInt8>.size))
        header.append(Data(bytes: &bigEndianLog2N, count: MemoryLayout<UInt8>.size))
        header.append(Data(bytes: &bigEndianR, count: MemoryLayout<UInt32>.size))
        header.append(Data(bytes: &bigEndianP, count: MemoryLayout<UInt32>.size))

        // 32 bytes salt
        header.append(Data(salt))

        // 16 bytes SHA256 checksum of bytes 0-47
        let precccount = header.count
        let precc = header.base64EncodedString()
        let checksum = header.prefix(48).sha256()
//        header.append(Data(checksum))
        header.append(Data(checksum.prefix(16)))

        let prehmaccount = header.count
        let prehmacb64 = header.base64EncodedString()

        // 32 bytes HMAC hash of bytes 0-63 (using scrypt hash as key)
        let hmac = try HMAC(key: value, variant: .sha2(.sha256)).authenticate(Array(header.prefix(64)))
        header.append(Data(hmac))
        
        let posthmaccount = header.count
        
        // Base64 encode the header
        let base64Header = header.base64EncodedString()
        
        
        print("Pre checksum: \(precccount); Pre HMAC: \(prehmaccount); Post HMAC: \(posthmaccount); HMAC: \(hmac.count)")
        print("Pre CC value:     \(precc)")
        print("Pre HMAC value:   \(prehmacb64)")
        print("Post HMAC value:  \(base64Header)")


        return base64Header
    }
}
