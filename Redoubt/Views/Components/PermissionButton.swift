import SwiftUI
import UserNotifications
import LocalAuthentication
import Combine

struct PermissionButton: View {
    let title: String
    let systemImageName: String
    let permissionType: PermissionType

    @State private var isEnabled: Bool = false
    @State private var isCheckingStatus: Bool = true
    @State private var canRequestDirectly: Bool = true // For notifications: can we show system prompt or must go to Settings?
    @State private var biometryType: LABiometryType = .none // For biometrics: which type is available

    enum PermissionType {
        case notifications
        case biometrics
    }

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                if !isEnabled {
                    requestPermission()
                }
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        Image(systemName: displayIconName)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)

                        if isEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.white).frame(width: 26, height: 26))
                                .offset(x: 20, y: -20)
                        }
                    }

                    Text(buttonText)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonBackgroundColor)
                .foregroundColor(buttonForegroundColor)
                .cornerRadius(12)
            }
            .disabled(isButtonDisabled)

            Text(displayTitle)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            checkPermissionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkPermissionStatus()
        }
    }

    private var displayIconName: String {
        if permissionType == .biometrics {
            switch biometryType {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            case .none, .opticID:
                return "faceid"
            @unknown default:
                return "faceid"
            }
        }
        return systemImageName
    }

    private var displayTitle: String {
        if permissionType == .biometrics {
            switch biometryType {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            case .none, .opticID:
                return "No Biometrics"
            @unknown default:
                return "No Biometrics"
            }
        }
        return title
    }

    private var buttonBackgroundColor: Color {
        if permissionType == .biometrics && biometryType == .none {
            return Color.gray.opacity(0.3)
        }
        return isEnabled ? Color.gray.opacity(0.3) : Color.blue
    }

    private var buttonForegroundColor: Color {
        if permissionType == .biometrics && biometryType == .none {
            return .gray
        }
        return isEnabled ? .primary : .white
    }

    private var isButtonDisabled: Bool {
        if permissionType == .biometrics && biometryType == .none {
            return true
        }
        return isEnabled
    }

    private var buttonText: String {
        if isEnabled {
            return "Enabled"
        } else if permissionType == .notifications && !canRequestDirectly {
            return "Open Settings"
        } else {
            return "Enable"
        }
    }

    private func checkPermissionStatus() {
        switch permissionType {
        case .notifications:
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.isEnabled = settings.authorizationStatus == .authorized
                    self.canRequestDirectly = settings.authorizationStatus == .notDetermined
                    self.isCheckingStatus = false
                }
            }
        case .biometrics:
            let context = LAContext()
            var error: NSError?
            let canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            DispatchQueue.main.async {
                self.biometryType = context.biometryType
                self.isEnabled = canUseBiometrics
                self.isCheckingStatus = false
            }
        }
    }

    private func requestPermission() {
        switch permissionType {
        case .notifications:
            if canRequestDirectly {
                // User hasn't been asked yet, show system permission prompt
                NotificationManager.shared.requestPermission { success in
                    DispatchQueue.main.async {
                        self.isEnabled = success
                        // After requesting, check status again to update UI properly
                        self.checkPermissionStatus()
                    }
                }
            } else {
                // User previously denied, must go to Settings to enable
                openSettings()
            }
        case .biometrics:
            // For biometrics, we can only check if it's available, not request it
            // This opens Settings if biometrics is not set up
            openSettings()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct PermissionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                PermissionButton(
                    title: "Notifications",
                    systemImageName: "bell.fill",
                    permissionType: .notifications
                )
                PermissionButtonMockEnabled(
                    title: "Notifications",
                    systemImageName: "bell.fill"
                )
            }

            HStack(spacing: 20) {
                PermissionButton(
                    title: "Face ID",
                    systemImageName: "faceid",
                    permissionType: .biometrics
                )
                PermissionButtonMockUnavailable(
                    title: "No Biometrics",
                    systemImageName: "faceid"
                )
            }

            HStack(spacing: 20) {
                PermissionButtonMockEnabled(
                    title: "Face ID",
                    systemImageName: "faceid"
                )
                PermissionButtonMockEnabled(
                    title: "Touch ID",
                    systemImageName: "touchid"
                )

            }
        }
        .padding()
    }
}

struct PermissionButtonMockEnabled: View {
    let title: String
    let systemImageName: String

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {}) {
                VStack(spacing: 8) {
                    ZStack {
                        Image(systemName: systemImageName)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.white).frame(width: 26, height: 26))
                            .offset(x: 20, y: -20)
                    }

                    Text("Enabled")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .disabled(true)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }
}

struct PermissionButtonMockUnavailable: View {
    let title: String
    let systemImageName: String

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {}) {
                VStack(spacing: 8) {
                    ZStack {
                        Image(systemName: systemImageName)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)
                    }

                    Text("Enable")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.gray)
                .cornerRadius(12)
            }
            .disabled(true)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }
}
