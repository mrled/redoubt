//
//  SecretDetailView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-28.
//


enum PasswordValidationStatus {
    case empty
    case valid
    case invalid
    case validating
}


import SwiftUI

struct SecretDetailView: View {
    @Binding var currentSecretId: UUID?
    @State private var passphrase = ""
    @State private var validity: PasswordValidationStatus = .empty
    @State private var showingDeleteAlert = false
    @State private var validationWorkItem: DispatchWorkItem?
    @FocusState private var isFocused: Bool
    @EnvironmentObject var secretsModel: SecretsViewModel
    
    // Delay a bit before notifying the user that their password is .empty or .invalid.
    // A .valid result will happen right away, but for invalid or empty results,
    // this gives users a bit to type the next character before being told they're Wrong.
    private let validationDelaySecs: Double = 1.0
    
    var body: some View {
        if let unwrappedSecret = secret {
            ScrollView {
                SecureField("Passphrase", text: $passphrase, onCommit: validatePassphrase)
                    .keyboardType(.default)
                    .focused($isFocused)
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
                    .padding()
                Spacer()
            }
            .padding()
            .navigationBarTitle(unwrappedSecret.name)
            .navigationBarItems(trailing: trailingNavBarItems)
            .onAppear {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
        } else {
            Text("No such secret ID: \(currentSecretId?.uuidString ?? "nil UUID")")
        }
    }
    
    var secret: Secret? {
        secretsModel.secrets.first(where: { $0.id == currentSecretId })
    }
    
    var currentSecretIndex: Int? {
        secretsModel.secrets.firstIndex { $0.id == currentSecretId }
    }
    
    var nextSecretId: UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let nextIndex = secretsModel.secrets.index(after: currentIndex)
        if nextIndex < secretsModel.secrets.count {
            return secretsModel.secrets[nextIndex].id
        } else {
            return nil
        }
    }

    var previousSecretId: UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let prevIndex = secretsModel.secrets.index(before: currentIndex)
        if prevIndex >= 0 {
            return secretsModel.secrets[prevIndex].id
        } else {
            return nil
        }
    }
    
    /// Items displayed in the upper right corner of the view
    private var trailingNavBarItems: some View {
        HStack {
            /// The delete button and its alert
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "delete.backward")
                    .foregroundColor(.red)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(title: Text("Delete Secret"),
                      message: Text("Are you sure you want to delete this secret? This action cannot be undone."),
                      primaryButton: .destructive(Text("Delete")) {
                          guard let unwrappedSecret = secret else { return }
                          secretsModel.deleteItem(unwrappedSecret)
                          let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
                          feedbackGenerator.impactOccurred()
                      },
                      secondaryButton: .cancel())
            }

            /// Next/previous item buttons
            Button(action: {
                guard let unwrappedPrevious = previousSecretId else { return }
                currentSecretId = unwrappedPrevious
            }) {
                Image(systemName: "arrow.left")
            }
            .disabled(currentSecretIndex == 0)

            Button(action: {
                guard let unwrappedNext = nextSecretId else { return }
                currentSecretId = unwrappedNext
            }) {
                Image(systemName: "arrow.right")
            }
            .disabled(currentSecretIndex == secretsModel.secrets.count - 1)
        }
    }
    
    /// Validate the passphrase out of the main thread
    ///
    /// Argon2 validation is a noticeably slow, so we do this outside of the main thread.
    /// We use a dispatch queue and the validationWorkItem to only allow one validation to happen at a time;
    /// if a new one is started, the old one is cancelled.
    private func validatePassphrase() {
        validationWorkItem?.cancel()
        
        validity = .validating
        
        /// We can't capture the whole struct in the thread closures,
        /// which means we have to copy specific variables we want to use in the closures into tmp variables rather than relying on instance properties.
        let tmpSecret = secret
        let tmpPassphrase = passphrase
        let tmpValidationDelaySecs = validationDelaySecs
        
        let item = DispatchWorkItem {
            // This is happening off the main thread
            // We cannot mutate struct properties on this thread
            // Also, take care not to reference state variables from this thread,
            // or else Swift will just run it synchronously (as if it were not threaded).
        
            if tmpSecret?.validate(plaintextIn: tmpPassphrase) ?? false {
                // Notify the user immediately as their passphrase is valid
                DispatchQueue.main.async {
                    validity = .valid
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)
                }
            } else if tmpPassphrase.isEmpty {
                // Notify the user after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + tmpValidationDelaySecs) {
                    validity = .empty
                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
                    feedbackGenerator.impactOccurred()
                }
            } else {
                // Notify the user after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + tmpValidationDelaySecs) {
                    // Only set to invalid if the passphrase hasn't changed during the wait
                    if passphrase == tmpPassphrase {
                        validity = .invalid
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.error)
                    }
                }
            }
        }
        
        validationWorkItem = item
        DispatchQueue.global(qos: .userInitiated).async(execute: item)
    }

    private var boxColor: Color {
        switch validity {
        case .empty: return .gray
        case .valid: return .green
        case .validating: return .blue
        case .invalid: return .red
        }
    }
    
    private var validationText: String {
        switch validity {
        case .empty: return "Enter passphrase..."
        case .valid: return "Correct!"
        case .validating: return "Validating..."
        case .invalid: return "Incorrect!"
        }
    }
}


struct SecretDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", plaintext: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
        ]
        let secretsModel = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleSecrets))
        Group {
            NavigationView {
                SecretDetailView(currentSecretId: .constant(secretsModel.secrets[0].id))
                    .environmentObject(secretsModel)
            }
            .previewDisplayName("Secret 1/2")
            NavigationView {
                SecretDetailView(currentSecretId: .constant(nil))
                    .environmentObject(secretsModel)
            }
            .previewDisplayName("Invalid secret")
        }
    }
}
