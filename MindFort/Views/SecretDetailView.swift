//
//  SecretDetailView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-28.
//

import SwiftUI

struct SecretDetailView: View {
    let secret: Secret
    let index: Int
    @State private var passphrase = ""
    @State private var passphraseValid: Bool = false
    @FocusState private var isFocused: Bool
    @EnvironmentObject var secretsModel: SecretsViewModel
    
    var body: some View {
        VStack {
            SecureField("Passphrase", text: $passphrase, onCommit: validatePassphrase)
                .keyboardType(.default)
                .focused($isFocused)
                .onChange(of: passphrase) { _ in
                    validatePassphrase()
                }
                .padding()
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(boxColor)
                .frame(height: 50)
                .overlay(
                    Text(validationText)
                        .foregroundColor(.white)
                )
                .padding()
            Spacer()
            Button("Delete") {
                secretsModel.deleteItem(secret)
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
                feedbackGenerator.impactOccurred()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(10)
            Text("H4XX0R C0D3")
                .font(.headline)
            Text(prettyHashBlock(digest: secret.digest, perLine: 4))
                .font(.system(size: 14, design: .monospaced))
                .padding()
            Spacer()
        }
        .padding()
        .navigationBarTitle(secret.name)
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
    
    private func validatePassphrase() {
        let passphraseWasValid = passphraseValid
        passphraseValid = secret.validate(input: passphrase)
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
    static let secret = try! Secret(name: "Test Secret", value: "hunter2")
    static var previews: some View {
        NavigationView {
            SecretDetailView(secret: secret, index: 1)
        }
    }
}
