import Foundation
import LocalAuthentication

protocol DeviceOwnerAuthHelperProtocol {
    func availability(context: DeviceOwnerAuthContexting) -> DeviceOwnerAuthAvailability
}

extension DeviceOwnerAuthHelperProtocol {
    func availability() -> DeviceOwnerAuthAvailability {
        availability(context: LAContext())
    }
}

protocol DeviceOwnerAuthContexting {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
}

extension LAContext: DeviceOwnerAuthContexting {}

struct DeviceOwnerAuthAvailability: Equatable {
    enum UnavailableReason: Equatable {
        case passcodeNotSet
        case biometryNotEnrolled
        case biometryNotAvailable
        case biometryLockout
        case unknown
    }

    let isSimulator: Bool
    let ownerAuthAvailable: Bool
    let isLockedOut: Bool
    let unavailableReason: UnavailableReason?
}

struct DeviceOwnerAuthHelper: DeviceOwnerAuthHelperProtocol {
    func availability(context: DeviceOwnerAuthContexting = LAContext()) -> DeviceOwnerAuthAvailability {
        var deviceOwnerError: NSError?
        let ownerAuthAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &deviceOwnerError)

        var isLockedOut = false
        var biometricsError: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &biometricsError)

        if let biometricsError = biometricsError, Self.errorCode(from: biometricsError) == .biometryLockout {
            isLockedOut = true
        }

        let unavailableReason: DeviceOwnerAuthAvailability.UnavailableReason?
        if ownerAuthAvailable {
            unavailableReason = nil
        } else if let deviceOwnerError = deviceOwnerError, let code = Self.errorCode(from: deviceOwnerError) {
            unavailableReason = Self.unavailableReason(from: code)
        } else {
            unavailableReason = .unknown
        }

        return DeviceOwnerAuthAvailability(
            isSimulator: Self.isRunningOnSimulator,
            ownerAuthAvailable: ownerAuthAvailable,
            isLockedOut: isLockedOut,
            unavailableReason: unavailableReason
        )
    }

    private static func unavailableReason(from code: LAError.Code) -> DeviceOwnerAuthAvailability.UnavailableReason {
        switch code {
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryLockout:
            return .biometryLockout
        default:
            return .unknown
        }
    }

    private static func errorCode(from error: NSError) -> LAError.Code? {
        guard error.domain == LAError.errorDomain else { return nil }
        return LAError.Code(rawValue: error.code)
    }

    private static var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
