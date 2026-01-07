import SwiftUI
import UserNotifications
import LocalAuthentication

struct PermissionButton: View {
    let title: String
    let systemImageName: String
    let permissionType: PermissionType

    @State private var isEnabled: Bool = false
    @State private var isCheckingStatus: Bool = true

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
                    Image(systemName: systemImageName)
                        .font(.system(size: 40))
                        .frame(width: 60, height: 60)

                    Text(isEnabled ? "Enabled" : "Enable")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEnabled ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(isEnabled ? .gray : .white)
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

    private func checkPermissionStatus() {
        switch permissionType {
        case .notifications:
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.isEnabled = settings.authorizationStatus == .authorized
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
            NotificationManager.shared.requestPermission { success in
                DispatchQueue.main.async {
                    self.isEnabled = success
                }
            }
        case .biometrics:
            // For biometrics, we can only check if it's available, not request it
            // This opens Settings if biometrics is not set up
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
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
                PermissionButton(
                    title: "Face ID / Touch ID",
                    systemImageName: "faceid",
                    permissionType: .biometrics
                )
            }
            .padding()
        }
    }
}
