import SwiftUI


/// Possible alerts the Settings sheet can show
enum DemoModeAlertType {
    case none
    case ownerAuthUnavailable
    case ownerAuthFailed
}


struct DemoModeSheet: View {
    @Binding var isPresentingDemoMode: Bool
    
    @AppStorage(MFAStorage.K.demoMode) var demoMode: Bool = MFAStorage.D.demoMode
    
    @State private var showAlert: Bool = false
    @State private var alertType: DemoModeAlertType = .none
    @State private var availability: DeviceOwnerAuthAvailability

    private let authHelper: DeviceOwnerAuthHelperProtocol
    private let demoModeCoordinator: DemoModeCoordinator

    init(
        isPresentingDemoMode: Binding<Bool>,
        demoModeCoordinator: DemoModeCoordinator? = nil,
        authHelper: DeviceOwnerAuthHelperProtocol = DeviceOwnerAuthHelper()
    ) {
        self._isPresentingDemoMode = isPresentingDemoMode
        self.demoModeCoordinator = demoModeCoordinator ?? DemoModeCoordinator(authHelper: authHelper)
        self.authHelper = authHelper
        self._availability = State(initialValue: authHelper.availability())
    }

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
                    Text("Let someone else try the app with example password entries.")
                        .padding(.bottom, 8)
                    availabilityNotice
                        .padding(.bottom, 8)
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
            case .ownerAuthUnavailable:
                return Alert(
                    title: Text("Device owner authentication required"),
                    message: Text("Enable a passcode or biometrics in Settings to enter or exit demo mode."),
                    dismissButton: .default(Text("OK"))
                )
            case .ownerAuthFailed:
                return Alert (
                    title: Text("Authentication failed"),
                    message: Text("Could not verify device owner."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear(perform: refreshAvailability)
    }
    
    /// Single entry point for demo mode toggling: checks availability and handles alerts.
    func performDemoModeToggleIfAllowed() {
        demoModeCoordinator.performToggleIfAllowed(
            onToggle: {
                toggleDemoModeState()
                refreshAvailability()
            },
            onAlert: { alert in
                alertType = alert
                showAlert = true
            }
        )
    }

    private var availabilityNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            if availability.isSimulator {
                Text("In the simulator, demo mode can be entered/exited without authentication.")
            } else if availability.ownerAuthAvailable {
                Text("Authentication will be required to enter or exit demo mode.")
            } else {
                warningBox(reason: availability.unavailableReason)
            }
        }
    }

    private func warningBox(reason: DeviceOwnerAuthAvailability.UnavailableReason?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Owner authentication unavailable. Entry/exit is blocked until a passcode is enabled.")
                .bold()
            if let reasonText = unavailableReasonText(from: reason) {
                Text(reasonText)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    private func label(text: String, color: Color) -> some View {
        HStack {
            Image(systemName: "info.circle.fill")
            Text(text)
        }
        .foregroundColor(color)
    }

    private func refreshAvailability() {
        availability = authHelper.availability()
    }

    private func unavailableReasonText(from reason: DeviceOwnerAuthAvailability.UnavailableReason?) -> String? {
        guard let reason = reason else { return nil }
        switch reason {
        case .passcodeNotSet:
            return "Set a device passcode to enable authentication."
        case .biometryNotEnrolled:
            return "Enroll Face ID or Touch ID, or set a passcode."
        case .biometryNotAvailable:
            return "Biometrics are not available on this device. Use a passcode."
        case .biometryLockout:
            return "Too many failed attempts. Unlock your device with passcode."
        case .unknown:
            return nil
        }
    }

    func toggleDemoModeState() {
        demoMode.toggle()
        isPresentingDemoMode = false
    }
}

struct DemoModeSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DemoModeSheet(
                isPresentingDemoMode: .constant(true),
                demoModeCoordinator: DemoModeCoordinator(authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: true, ownerAuthAvailable: false, isLockedOut: false, unavailableReason: nil))),
                authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: true, ownerAuthAvailable: false, isLockedOut: false, unavailableReason: nil))
            )
            .previewDisplayName("Simulator - no auth needed")

            DemoModeSheet(
                isPresentingDemoMode: .constant(true),
                demoModeCoordinator: DemoModeCoordinator(authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: false, ownerAuthAvailable: true, isLockedOut: false, unavailableReason: nil))),
                authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: false, ownerAuthAvailable: true, isLockedOut: false, unavailableReason: nil))
            )
            .previewDisplayName("Device - auth available")

            DemoModeSheet(
                isPresentingDemoMode: .constant(true),
                demoModeCoordinator: DemoModeCoordinator(authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: false, ownerAuthAvailable: false, isLockedOut: false, unavailableReason: .passcodeNotSet))),
                authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: false, ownerAuthAvailable: false, isLockedOut: false, unavailableReason: .passcodeNotSet))
            )
            .previewDisplayName("Device - auth unavailable (no passcode)")

            // We expect this to work the same as if not locked out.
            // The system will propmt the user for a passcode,
            // but that doesn't have to change what we display.
            DemoModeSheet(
                isPresentingDemoMode: .constant(true),
                demoModeCoordinator: DemoModeCoordinator(authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: false, ownerAuthAvailable: true, isLockedOut: true, unavailableReason: .biometryLockout))),
                authHelper: DeviceOwnerAuthHelperStub(.init(isSimulator: false, ownerAuthAvailable: true, isLockedOut: true, unavailableReason: .biometryLockout))
            )
            .previewDisplayName("Device - lockout")
        }
    }
}

private struct DeviceOwnerAuthHelperStub: DeviceOwnerAuthHelperProtocol {
    let availabilityToReturn: DeviceOwnerAuthAvailability

    init(_ availability: DeviceOwnerAuthAvailability) {
        self.availabilityToReturn = availability
    }

    func availability(context: DeviceOwnerAuthContexting) -> DeviceOwnerAuthAvailability {
        availabilityToReturn
    }
}
