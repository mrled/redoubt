import SwiftUI
import UserNotifications
import LocalAuthentication

struct PermissionButton: View {
    let title: String
    let systemImageName: String
    let permissionType: PermissionType

    @State private var isEnabled: Bool = false
    @State private var isCheckingStatus: Bool = true
    @State private var canRequestDirectly: Bool = true // For notifications: can we show system prompt or must go to Settings?

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
                        Image(systemName: systemImageName)
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
                .background(isEnabled ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(isEnabled ? .primary : .white)
                .cornerRadius(12)
            }
            .disabled(isEnabled)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            checkPermissionStatus()
        }
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
            DispatchQueue.main.async {
                self.isEnabled = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
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
            Text("Active State")
                .font(.headline)
            HStack(spacing: 20) {
                PermissionButton(
                    title: "Notifications",
                    systemImageName: "bell.fill",
                    permissionType: .notifications
                )
                PermissionButton(
                    title: "Face ID / Touch ID",
                    systemImageName: "faceid",
                    permissionType: .biometrics
                )
            }

            Divider()
                .padding(.vertical)

            Text("Done + Disabled State")
                .font(.headline)
            HStack(spacing: 20) {
                PermissionButtonMockEnabled(
                    title: "Notifications",
                    systemImageName: "bell.fill"
                )
                PermissionButtonMockEnabled(
                    title: "Face ID / Touch ID",
                    systemImageName: "faceid"
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
