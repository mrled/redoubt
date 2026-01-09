import SwiftUI
import UserNotifications
import Combine

struct PermissionButton: View {
    let title: String
    let systemImageName: String
    let permissionType: PermissionType

    enum PermissionType {
        case notifications
        case biometrics
    }

    @State private var isEnabled: Bool = false
    @State private var canRequestDirectly: Bool = true // For notifications: can we show system prompt or must go to Settings?

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
                .background(buttonBackgroundColor)
                .foregroundColor(buttonForegroundColor)
                .cornerRadius(12)
            }
            .disabled(isButtonDisabled)

            Text(title)
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

    private var buttonBackgroundColor: Color {
        return isEnabled ? Color.gray.opacity(0.3) : Color.blue
    }

    private var buttonForegroundColor: Color {
        return isEnabled ? .primary : .white
    }

    private var isButtonDisabled: Bool {
        return isEnabled
    }

    private var buttonText: String {
        if isEnabled {
            return "Enabled"
        } else if !canRequestDirectly {
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
                }
            }
        case .biometrics:
            // Placeholder for future biometrics handling; intentionally does not preflight auth.
            isEnabled = false
            canRequestDirectly = false
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
            // No-op for now; biometrics is not requested during onboarding.
            break
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
                PermissionButtonMockEnabled(
                    title: "Notifications",
                    systemImageName: "bell.fill"
                )
                PermissionButtonMockEnabled(
                    title: "Notifications (Settings)",
                    systemImageName: "bell.badge.fill"
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
