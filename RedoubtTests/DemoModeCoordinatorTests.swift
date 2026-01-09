import LocalAuthentication
import XCTest
@testable import Redoubt

final class DemoModeCoordinatorTests: XCTestCase {
    func testSimulatorBypassesAuthAndToggles() {
        let coordinator = DemoModeCoordinator(
            authHelper: DeviceOwnerAuthHelperStub(availability: .init(isSimulator: true, ownerAuthAvailable: false, isLockedOut: false, unavailableReason: nil)),
            contextProvider: { LAContextStub() }
        )

        var toggleCount = 0
        var receivedAlert: DemoModeAlertType?

        coordinator.performToggleIfAllowed(
            onToggle: { toggleCount += 1 },
            onAlert: { receivedAlert = $0 }
        )

        XCTAssertEqual(toggleCount, 1)
        XCTAssertNil(receivedAlert)
    }

    func testUnavailableAuthShowsUnavailableAlert() {
        let coordinator = DemoModeCoordinator(
            authHelper: DeviceOwnerAuthHelperStub(availability: .init(isSimulator: false, ownerAuthAvailable: false, isLockedOut: false, unavailableReason: .passcodeNotSet)),
            contextProvider: { LAContextStub() }
        )

        var toggleCount = 0
        var receivedAlert: DemoModeAlertType?

        coordinator.performToggleIfAllowed(
            onToggle: { toggleCount += 1 },
            onAlert: { receivedAlert = $0 }
        )

        XCTAssertEqual(toggleCount, 0)
        XCTAssertEqual(receivedAlert, .ownerAuthUnavailable)
    }

    func testAuthSuccessToggles() {
        let expectation = expectation(description: "toggle succeeds")
        let coordinator = DemoModeCoordinator(
            authHelper: DeviceOwnerAuthHelperStub(availability: .init(isSimulator: false, ownerAuthAvailable: true, isLockedOut: false, unavailableReason: nil)),
            contextProvider: {
                let context = LAContextStub()
                context.canEvaluatePolicyResult = (true, nil)
                context.evaluatePolicyResult = true
                return context
            }
        )

        var toggleCount = 0
        var receivedAlert: DemoModeAlertType?

        coordinator.performToggleIfAllowed(
            onToggle: {
                toggleCount += 1
                expectation.fulfill()
            },
            onAlert: { alert in
                receivedAlert = alert
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(toggleCount, 1)
        XCTAssertNil(receivedAlert)
    }

    func testBiometricLockoutStillAllowsPasscodeAuthAndToggle() {
        let expectation = expectation(description: "passcode auth succeeds after lockout")
        let coordinator = DemoModeCoordinator(
            authHelper: DeviceOwnerAuthHelperStub(availability: .init(isSimulator: false, ownerAuthAvailable: true, isLockedOut: true, unavailableReason: .biometryLockout)),
            contextProvider: {
                let context = LAContextStub()
                context.canEvaluatePolicyResult = (true, NSError(domain: LAError.errorDomain, code: LAError.biometryLockout.rawValue))
                context.evaluatePolicyResult = true
                return context
            }
        )

        var toggleCount = 0
        var receivedAlert: DemoModeAlertType?

        coordinator.performToggleIfAllowed(
            onToggle: {
                toggleCount += 1
                expectation.fulfill()
            },
            onAlert: { alert in
                receivedAlert = alert
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(toggleCount, 1)
        XCTAssertNil(receivedAlert)
    }

    func testAuthFailureShowsFailedAlert() {
        let expectation = expectation(description: "auth fails")
        let coordinator = DemoModeCoordinator(
            authHelper: DeviceOwnerAuthHelperStub(availability: .init(isSimulator: false, ownerAuthAvailable: true, isLockedOut: false, unavailableReason: nil)),
            contextProvider: {
                let context = LAContextStub()
                context.canEvaluatePolicyResult = (true, nil)
                context.evaluatePolicyResult = false
                return context
            }
        )

        var toggleCount = 0
        var receivedAlert: DemoModeAlertType?

        coordinator.performToggleIfAllowed(
            onToggle: {
                toggleCount += 1
                expectation.fulfill()
            },
            onAlert: { alert in
                receivedAlert = alert
                expectation.fulfill()
            }
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(toggleCount, 0)
        XCTAssertEqual(receivedAlert, .ownerAuthFailed)
    }
}

private struct DeviceOwnerAuthHelperStub: DeviceOwnerAuthHelperProtocol {
    let availabilityToReturn: DeviceOwnerAuthAvailability

    init(availability: DeviceOwnerAuthAvailability) {
        self.availabilityToReturn = availability
    }

    func availability(context: DeviceOwnerAuthContexting) -> DeviceOwnerAuthAvailability {
        availabilityToReturn
    }
}

private final class LAContextStub: LAContext {
    var canEvaluatePolicyResult: (Bool, NSError?) = (false, nil)
    var evaluatePolicyResult: Bool = false

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let err = canEvaluatePolicyResult.1 {
            error?.pointee = err
        }
        return canEvaluatePolicyResult.0
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        reply(evaluatePolicyResult, nil)
    }
}
