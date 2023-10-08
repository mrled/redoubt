//
//  DevTextFieldPlayground.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-12.
//

import SwiftUI

struct DevTextFieldPlayground: View {
    @Binding var currentSecretId: UUID?
    @State private var showingDeleteAlert = false
    @State private var passphrase = ""
    @State private var previousMessage = ""
    @State private var message: String? = nil
    @State private var validity: PasswordValidationStatus = .invalid
    @State private var previousCompletedValidity: PasswordValidationStatus = .invalid
    @State private var validationWorkItem: DispatchWorkItem?
    @FocusState private var isFocused: Bool

    @EnvironmentObject var secretsVm: SecretsViewModel

    var secret: Secret? {
        secretsVm.secrets.first(where: { $0.id == currentSecretId })
    }
    
    
    var body: some View {
        List {
            Section {
                Button("Clear all", action: clearAll)
            }
            Section {
                Text(message != nil ? message! : "Enter a passphrase...")
            }
            Section {
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
            }
            Section("SecureField") {
                SecureField("Passphrase", text: $passphrase, onCommit: validatePassphrase)
                    .keyboardType(.default)
                    .onChange(of: passphrase) { _ in
                        validatePassphrase()
                    }
                    .focused($isFocused)
            }
            Section("TextField") {
                TextField("Passphrase", text: $passphrase, onCommit: validatePassphrase)
                    .keyboardType(.default)
                    .onChange(of: passphrase) { _ in
                        validatePassphrase()
                    }
            }
            Section("UIKitTextField") {
                UIKitTextField("Passphrase", text: $passphrase, onCommit: validatePassphrase)
                    .keyboardType(.default)
                    .onChange(of: passphrase) { _ in
                        validatePassphrase()
                    }
            }
            Section("UIKitTextField isSecureEntry:true") {
                UIKitTextField("Passphrase", text: $passphrase, isSecureTextEntry: true, onCommit: validatePassphrase)
                    .keyboardType(.default)
                    .onChange(of: passphrase) { _ in
                        validatePassphrase()
                    }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }

    }
    
    /// Validate the passphrase out of the main thread
    ///
    /// Argon2 validation is a noticeably slow, so we do this outside of the main thread.
    /// We use a dispatch queue and the validationWorkItem to only allow one validation to happen at a time;
    /// if a new one is started, the old one is cancelled.
    private func validatePassphrase() {
        validationWorkItem?.cancel()
        var tmpPreviousCompletedValidity = previousCompletedValidity
        if validity != .validating {
            tmpPreviousCompletedValidity = validity
        }
        validity = .validating
        let tmpSecret = secret
        let tmpPassphrase = passphrase

        let item = DispatchWorkItem {
            // This is happening off the main thread
            // We cannot mutate struct properties on this thread
            // Also, take care not to reference state variables from this thread,
            // or else Swift will just run it synchronously (as if it were not threaded).

            var tmpValidity: PasswordValidationStatus
            if tmpSecret?.validate(plaintextIn: tmpPassphrase) ?? false {
                tmpValidity = .valid
            } else {
                tmpValidity = .invalid
            }

            // However, updating state variables must happen in the main thread
            // I think this is true of haptic feedback too?
            DispatchQueue.main.async {
                previousCompletedValidity = tmpPreviousCompletedValidity
                validity = tmpValidity
                if validity == .valid {
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)
                } else if previousCompletedValidity == .valid && validity == .invalid {
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.error)
                }
            }
        }
        
        validationWorkItem = item
        DispatchQueue.global(qos: .userInitiated).async(execute: item)
    }


    
    private func validatePassphraseFAST() {
        validationWorkItem?.cancel()
        var tmpPreviousCompletedValidity = previousCompletedValidity
        if validity != .validating {
            tmpPreviousCompletedValidity = validity
        }
        validity = .validating
        var tmpPreviousMessage = message ?? ""
        let tmpPassphrase = passphrase
        let tmpSecretName = secret?.name ?? "(nil)"
        let tmpSecret = secret

        let item = DispatchWorkItem {
            var tmpMessage = "Trying \(tmpPassphrase.count) letters for \(tmpSecretName)"
            var tmpValidity: PasswordValidationStatus
            if tmpSecret?.validate(plaintextIn: tmpPassphrase) ?? false {
                tmpValidity = .valid
            } else {
                tmpValidity = .invalid
            }
            sleep(1)
            DispatchQueue.main.async {
                previousMessage = tmpPreviousMessage
                message = tmpMessage
                validity = tmpValidity
                if tmpValidity == .valid {
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.success)

                }
            }
        }
        validationWorkItem = item
        DispatchQueue.global(qos: .userInitiated).async(execute: item)
    }

    
    private func clearAll() {
        passphrase = ""
        message = nil
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

    var currentSecretIndex: Int? {
        secretsVm.secrets.firstIndex { $0.id == currentSecretId }
    }
    
    var nextSecretId: UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let nextIndex = secretsVm.secrets.index(after: currentIndex)
        if nextIndex < secretsVm.secrets.count {
            return secretsVm.secrets[nextIndex].id
        } else {
            return nil
        }
    }

    var previousSecretId: UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let prevIndex = secretsVm.secrets.index(before: currentIndex)
        if prevIndex >= 0 {
            return secretsVm.secrets[prevIndex].id
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
                          secretsVm.removeSecret(unwrappedSecret)
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
            .disabled(currentSecretIndex == secretsVm.secrets.count - 1)
        }
    }


}

struct DevTextFieldPlayground_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", plaintext: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
        ]
        let exampleCollection = SecretCollection(secrets: exampleSecrets, regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
        let secretsPreviewVm = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollection))
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                DevTextFieldPlayground(currentSecretId: .constant(secretsPreviewVm.secrets[0].id))
                    .environmentObject(secretsPreviewVm)
            }
    }
}


