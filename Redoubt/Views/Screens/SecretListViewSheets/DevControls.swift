import SwiftUI

struct DevControls: View {
    @EnvironmentObject var secretsVm: SecretsViewModel

    var body: some View {
        List {
            Section("Developer tools") {
                NavigationLink(destination: DevNotifications()) {
                    Text("Notifications debugger")
                }
                NavigationLink(destination: DevHapticPlayground()) {
                    Text("Haptic playground")
                }
                if secretsVm.secrets.isEmpty {
                    Text("Add a secret to enable the text field playground")
                } else {
                    NavigationLink(destination: DevTextFieldPlayground(currentSecretId: .constant(secretsVm.secrets[0].id))) {
                        Text("Text field playground")
                    }
                }
            }
        }
        .navigationTitle("Developer options")
    }
}

#Preview {
    NavigationStack {
        DevControls()
    }
    .environmentObject(SecretsViewModel())
}
