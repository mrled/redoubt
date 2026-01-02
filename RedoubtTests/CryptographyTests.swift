import XCTest

import Sodium

@testable import Redoubt

final class CryptographyTests: XCTestCase {
    
    var sodium = Sodium()

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testArgon2Passwords() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let password = "password"
        let hashedPassword = sodium.pwHash.str(passwd: Array(password.utf8), opsLimit: sodium.pwHash.OpsLimitInteractive, memLimit: sodium.pwHash.MemLimitInteractive)!
        let correctResult = "$argon2id$v=19$m=65536,t=2,p=1$EVb08m0jXkJggXxUUD0lnQ$siuIutCU/4iy2VKDBs8nVsEgF2rJUzvuG96CtFS1xBM"
        // NOTE: these will not match, as they do not have the same salt
        print("Calculated result: \(hashedPassword)")
        print("Correct    result: \(correctResult)")
        XCTAssert(sodium.pwHash.strVerify(hash: correctResult, passwd: Array(password.utf8)))
    }
}
