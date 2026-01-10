import SwiftUI

struct SecretQuizInnerView: View {
    /// The secret associated with this view
    @Binding var secret: Secret
    
    /// The secret ID for the currently in-view quiz card - maybe this view, or another instance of it
    @Binding var currentSecretId: UUID?

    /// A FocusState managed by the parent view, see there for documentation
    var activeView: FocusState<UUID?>.Binding

    /// A callback to execute when the quiz should advance to the next secret
    var onAdvance: () -> Void
    
    @State private var passphraseValid = false
    @State private var passphrase = ""
    
    @EnvironmentObject var secretsVm: SecretsViewModel
    
    var body: some View {
        ScrollView {
            Text(secret.name)
                .font(.title)
                .bold()
            SecureField("Passphrase", text: $passphrase, onCommit: validatePassphrase)
                .keyboardType(.default)
                .focused(activeView, equals: secret.id)
                .onChange(of: passphrase) { _ in
                    validatePassphrase()
                }
                .padding()
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(boxColor)
                .frame(height: 175)
                .overlay(
                    VStack {
                        Text(validationText)
                            .foregroundColor(.white)
                            .padding([.bottom])
                        H4XX0RC0D3(password: $passphrase, foregroundColor: .white)
                    }
                )
                .animation(.default, value: boxColor)
                .padding()
            Button(action: handleForgotPassword) {
                Text("I forgot this passphrase")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.horizontal)
            Spacer()
        }
        .padding()
        .navigationBarTitle("Pop quiz!")
        .onAppear {
            if currentSecretId == nil {
                currentSecretId = secretsVm.secrets[0].id
            }
            CustomLogger.secretIds(message: "SecretQuizInnerView onAppear: currentSecretId: \(currentSecretId?.uuidString ?? "nil")")
            for secret in secretsVm.secrets {
                CustomLogger.secretIds(message: " - SecretQuizInnerView onAppear: \(secret.id)")
            }
        }
    }
    
    var currentSecretIndex: Int? {
        secretsVm.secrets.firstIndex { $0.id == currentSecretId }
    }
    
    /// True if my .secret property has the same ID as currentSecretId
    var secretIsCurrent: Bool {
        return secret.id == currentSecretId
    }
    
    private func validatePassphrase() {
        let passphraseWasValid = passphraseValid
        passphraseValid = secret.validate(plaintextIn: passphrase)
        if !passphraseWasValid && passphraseValid {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
            onAdvance()
        } else if passphraseWasValid && !passphraseValid {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.error)
        }
    }

    private func handleForgotPassword() {
        secret.lastQuizPassed = false
        secret.lastQuizzed = Date()
        secret.consecutiveSuccesses = 0
        passphraseValid = false
        passphrase = ""
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.warning)
        onAdvance()
    }
    
    private var boxColor: Color {
        if passphrase.isEmpty {
            return .gray
        } else if passphraseValid {
            return .green
        } else {
            return .red
        }
    }
    
    private var validationText: String {
        if passphrase.isEmpty {
            return "Enter passphrase..."
        } else if passphraseValid {
            return "Correct!"
        } else {
            return "Incorrect!"
        }
    }
}

struct SecretQuizInnerView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", plaintext: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
        ]
        let exampleCollection = SecretCollection(secrets: exampleSecrets)
        let secretsPreviewVm = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollection))
        
        /// Just a dummy to make the preview compile - doesn't actually set the focus
        @FocusState var activeView: UUID?

        Group {
            NavigationView {
                SecretQuizInnerView(
                    secret: .constant(exampleSecrets[0]),
                    currentSecretId: .constant(secretsPreviewVm.secrets[0].id),
                    activeView: $activeView,
                    onAdvance: {}
                )
            }
            .previewDisplayName("Secret 1/2")
            
            NavigationView {
                SecretQuizInnerView(
                    secret: .constant(exampleSecrets[0]),
                    currentSecretId: .constant(nil),
                    activeView: $activeView,
                    onAdvance: {}
                )
            }
            .previewDisplayName("Invalid secret")
        }
        .environmentObject(secretsPreviewVm)
    }
}
