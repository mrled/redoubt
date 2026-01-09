import SwiftUI


/// Possible alerts the Settings sheet can show
enum DemoModeAlertType {
    case none
    case biometricsUnavailable
    case biometricsFailed
    case biometricsLockedOut
}


struct DemoModeSheet: View {
    @Binding var isPresentingDemoMode: Bool
    
    @AppStorage(MFAStorage.K.demoMode) var demoMode: Bool = MFAStorage.D.demoMode
    
    @State private var showAlert: Bool = false
    @State private var alertType: DemoModeAlertType = .none
    private let demoModeCoordinator = DemoModeCoordinator()

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer() // The spacers center content horizontally even though the parent VStack is alignment:.leading
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                Text("Demonstration Mode")
                    .font(.title)
                    .bold()
                    .padding()
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                Spacer()
            }
            HStack {
                Text("Temporarily fill the app with example password entries")
                    .font(.title2)
                    .padding([.top, .bottom])
            }
            Group {
                VStack(alignment: .leading) {
                    Text("Let someone else try the app with example password entries. Entering/exiting demo mode requires authentication.")
                }
                Button(action: performDemoModeToggleIfAllowed) {
                    HStack {
                        Image(systemName: "tv")
                            .frame(width: 32, height: 32)
                        if demoMode {
                            Text("Exit demo mode")
                                .foregroundColor(.green)
                        } else {
                            Text("Enter demo mode")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .none:
                return Alert(
                    title: Text("Something went wrong"),
                    message: Text("This should never happen"),
                    dismissButton: .default(Text("OK"))
                )
            case .biometricsUnavailable:
                return Alert(
                    title: Text("Biometrics unavailable"),
                    message: Text("Please set up Face ID or Touch ID in your device settings"),
                    dismissButton: .default(Text("OK"))
                )
            case .biometricsFailed:
                return Alert (
                    title: Text("Biometrics failed"),
                    message: Text("Could not authenticate with Face ID or Touch ID"),
                    dismissButton: .default(Text("OK"))
                )
            case .biometricsLockedOut:
                return Alert (
                    title: Text("Biometrics locked out"),
                    message: Text("Too many Face ID or Touch ID failures"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    /// Single entry point for demo mode toggling: checks availability and handles alerts.
    func performDemoModeToggleIfAllowed() {
        demoModeCoordinator.performToggleIfAllowed(
            onToggle: {
                toggleDemoModeState()
            },
            onAlert: { alert in
                alertType = alert
                showAlert = true
            }
        )
    }

    func toggleDemoModeState() {
        demoMode.toggle()
        isPresentingDemoMode = false
    }
}

struct DemoModeSheet_Previews: PreviewProvider {
    static var previews: some View {
        DemoModeSheet(isPresentingDemoMode: .constant(true))
    }
}
