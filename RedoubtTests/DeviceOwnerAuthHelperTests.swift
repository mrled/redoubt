import LocalAuthentication
import XCTest
@testable import Redoubt

final class DeviceOwnerAuthHelperTests: XCTestCase {
    func testAvailabilityIsTrueWhenPolicyCanBeEvaluated() {
        let helper = DeviceOwnerAuthHelper()
        let context = DeviceOwnerAuthContextStub(responses: [
            .deviceOwnerAuthentication: (true, nil),
            .deviceOwnerAuthenticationWithBiometrics: (true, nil),
        ])

        let availability = helper.availability(context: context)

        #if targetEnvironment(simulator)
        XCTAssertTrue(availability.isSimulator)
        #else
        XCTAssertFalse(availability.isSimulator)
        #endif
        XCTAssertTrue(availability.ownerAuthAvailable)
        XCTAssertFalse(availability.isLockedOut)
        XCTAssertNil(availability.unavailableReason)
    }

    func testPasscodeNotSetReportedWhenOwnerAuthUnavailable() {
        let helper = DeviceOwnerAuthHelper()
        let context = DeviceOwnerAuthContextStub(responses: [
            .deviceOwnerAuthentication: (false, NSError(domain: LAError.errorDomain, code: LAError.Code.passcodeNotSet.rawValue)),
            .deviceOwnerAuthenticationWithBiometrics: (true, nil),
        ])

        let availability = helper.availability(context: context)

        XCTAssertFalse(availability.ownerAuthAvailable)
        XCTAssertEqual(availability.unavailableReason, .passcodeNotSet)
        XCTAssertFalse(availability.isLockedOut)
    }

    func testLockoutIsReportedWhenBiometricsAreLocked() {
        let helper = DeviceOwnerAuthHelper()
        let context = DeviceOwnerAuthContextStub(responses: [
            .deviceOwnerAuthentication: (true, nil),
            .deviceOwnerAuthenticationWithBiometrics: (false, NSError(domain: LAError.errorDomain, code: LAError.Code.biometryLockout.rawValue)),
        ])

        let availability = helper.availability(context: context)

        XCTAssertTrue(availability.ownerAuthAvailable)
        XCTAssertTrue(availability.isLockedOut)
        XCTAssertNil(availability.unavailableReason)
    }
}

private final class DeviceOwnerAuthContextStub: DeviceOwnerAuthContexting {
    private let responses: [LAPolicy: (Bool, NSError?)]

    init(responses: [LAPolicy: (Bool, NSError?)]) {
        self.responses = responses
    }

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        let response = responses[policy] ?? (false, nil)
        if let providedError = response.1 {
            error?.pointee = providedError
        }
        return response.0
    }
}
