import Foundation
import LocalAuthentication

struct DemoModeCoordinator {
    private let authHelper: DeviceOwnerAuthHelperProtocol
    private let contextProvider: () -> LAContext

    init(
        authHelper: DeviceOwnerAuthHelperProtocol = DeviceOwnerAuthHelper(),
        contextProvider: @escaping () -> LAContext = { LAContext() }
    ) {
        self.authHelper = authHelper
        self.contextProvider = contextProvider
    }

    /// Security boundary: all demo mode transitions should go through this method.
    func performToggleIfAllowed(
        onToggle: @escaping () -> Void,
        onAlert: @escaping (DemoModeAlertType) -> Void
    ) {
        let availability = authHelper.availability()

        if availability.isSimulator {
            onToggle()
            return
        }

        if availability.isLockedOut {
            onAlert(.biometricsLockedOut)
            return
        }

        guard availability.ownerAuthAvailable else {
            onAlert(.biometricsUnavailable)
            return
        }

        let context = contextProvider()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Please authenticate to change the setting."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        onToggle()
                    } else {
                        onAlert(.biometricsFailed)
                    }
                }
            }
        } else if let laError = error as? LAError, laError.code == .biometryLockout {
            let reason = "You've attempted too many times! Enter your passcode to enable biometrics."

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        onToggle()
                    } else {
                        onAlert(.biometricsFailed)
                    }
                }
            }
        } else {
            onAlert(.biometricsUnavailable)
        }
    }
}
