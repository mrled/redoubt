//
//  CryptographyTests.swift
//  MindFortTests
//
//  Created by Micah R Ledbetter on 2023-06-07.
//

import XCTest

import CryptoSwift

@testable import MindFort

final class CryptographyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScryptMfDefaults() throws {
        let password = "password"
        let salt = Array("saltydog".utf8)
        let hash = try scryptMfDefaults(password: password, salt: salt)
//        print(Data(hash).base64EncodedString())
        
        // I couldn't make this test pass
        // I'm not sure if node-scrypt actually is doing the right thing here? Or if my HMAC code is wrong. Going to give up lol, bye.
        //
        // This is an scrypt header I found in the node-scrypt documentation.
        // We test against it to be sure that we generate a header that looks the same.
        //
        // It makes a somewhat unusual choice of an N of only 4096,
        // presumably because this is a test value for a bad password so we might as well use something fast.
        //
        // I did a lot of staring at `echo <base64 gunk> | xxd`.
        let password1 = "password1"
        let salt1: [UInt8] = [
            0xc4, 0x34, 0xcf, 0x0a, 0x7b, 0x40, 0xd2, 0xe4, 0x97, 0x10, 0xa7, 0xd7, 0x8b, 0xc1, 0xef, 0x90,
            0x18, 0x58, 0x32, 0x2b, 0xad, 0x3f, 0x48, 0xff, 0xb1, 0x7d, 0xfa, 0x55, 0x46, 0x05, 0xf2, 0x8d,
        ]
        let passwordData1: Array<UInt8> = Array(password1.utf8)
        let hash1 = ScryptHashWIP(
            value: try! Scrypt(password: passwordData1, salt: salt1, dkLen: 32, N: 4096, r: 8, p: 1).calculate(),
            salt: salt1,
            N: 4096,
            r: 8,
            p: 1
        )
        let header1 = try! hash1.tarsnapHeader()
        let correct1 = "c2NyeXB0AAwAAAAIAAAAAcQ0zwp7QNLklxCn14vB75AYWDIrrT9I/7F9+lVGBfKN/1TH2hs/HboSy1ptzN0YzHJhC7PZIEPQzf2nuoaqVZg8VkKEJlo8/QaH7qjU2VwB"
        print(header1)
        print(correct1)
        XCTAssert(header1 == correct1)
    }

//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
