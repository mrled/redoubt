//
//  HashedSecretDetailView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-28.
//

import SwiftUI

struct SecretDetailView: View {
    let secret: HashedSecret
    let index: Int
    @State private var passphrase = ""
    @State private var passphraseValid: Bool = false
    @FocusState private var isFocused: Bool
    @EnvironmentObject var viewModel: HashedSecretViewModel
    
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
            Button(action: {
                viewModel.deleteItem(secret)
            }) {
                Text("Delete")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
            }
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
        passphraseValid = secret.validate(input: passphrase)
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


struct HashedSecretDetailView_Previews: PreviewProvider {
    static let secret = try! HashedSecret(name: "Test Secret", value: "hunter2")
    static var previews: some View {
        SecretDetailView(secret: secret, index: 1)
    }
}
