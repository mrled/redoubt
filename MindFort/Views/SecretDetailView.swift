//
//  SecretDetailView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-28.
//

import SwiftUI

struct SecretDetailView: View {
    @Binding var currentSecretId: UUID?
    @State private var passphrase = ""
    @State private var passphraseValid: Bool = false
    @State private var showingDeleteAlert = false
    @FocusState private var isFocused: Bool
    @EnvironmentObject var secretsModel: SecretsViewModel
    
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
    
    private func validatePassphrase() {
        let passphraseWasValid = passphraseValid
        passphraseValid = secret?.validate(input: passphrase) ?? false
        if !passphraseWasValid && passphraseValid {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
        } else if passphraseWasValid && !passphraseValid {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.error)
        }
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


struct SecretDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", value: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", value: "showmethemoney"),
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
