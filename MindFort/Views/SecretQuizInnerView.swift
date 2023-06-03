//
//  SecretQuizView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-02.
//

import SwiftUI

struct SecretQuizInnerView: View {
    @Binding var currentSecretId: UUID?
//    @Binding var passphraseValid: Bool
    var onCorrectPassword: () -> Void
    @State private var passphraseValid = false
    @State private var passphrase = ""
    @FocusState private var isFocused: Bool
    @EnvironmentObject var secretsModel: SecretsViewModel
    
    var body: some View {
        ScrollView {
            Text(secret?.name ?? "(invalid??)")
                .font(.title)
                .bold()
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
                .animation(.default, value: boxColor)
                .padding()
            Spacer()
        }
        .padding()
        .navigationBarTitle("Pop quiz!")
        .onAppear {
            if currentSecretId == nil {
                currentSecretId = secretsModel.secrets[0].id
            }
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
    
    var secret: Secret? {
        secretsModel.secrets.first(where: { $0.id == currentSecretId })
    }
    
    var currentSecretIndex: Int? {
        secretsModel.secrets.firstIndex { $0.id == currentSecretId }
    }
        
    private func validatePassphrase() {
        let passphraseWasValid = passphraseValid
        passphraseValid = secret?.validate(input: passphrase) ?? false
        if !passphraseWasValid && passphraseValid {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
            onCorrectPassword()
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

struct SecretQuizInnerView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", value: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", value: "showmethemoney"),
        ]
        let secretsModel = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleSecrets))
        // WARNING: These won't indicate a correct passphrase in the preview because passphraseValid is set to false
        Group {
            NavigationView {
                SecretQuizInnerView(
                    currentSecretId: .constant(secretsModel.secrets[0].id),
//                    passphraseValid: .constant(false),
                    onCorrectPassword: {}
                )
                .environmentObject(secretsModel)
            }
            .previewDisplayName("Secret 1/2")
            NavigationView {
                SecretQuizInnerView(
                    currentSecretId: .constant(nil),
//                    passphraseValid: .constant(false),
                    onCorrectPassword: {}
                )
                .environmentObject(secretsModel)
            }
            .previewDisplayName("Invalid secret")
        }
    }
}
