//
//  SecretQuizView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-02.
//

import SwiftUI

struct SecretQuizView: View {
    @Binding var currentSecretId: UUID?
    @State private var previousSecretId: UUID?
//    @State private var passphrase = ""
//    @State private var passphraseValid: Bool = false
//    @State private var isFlipped: Bool = false
    @State private var finished: Bool = false
    @EnvironmentObject var secretsModel: SecretsViewModel
    
    var body: some View {
        ZStack {
            ForEach(secretsModel.secrets) { secret in
                SecretQuizInnerView(currentSecretId: $currentSecretId) {
                    if let nextSecretId = getNextSecretId() {
                        currentSecretId = nextSecretId
                    } else {
                        finished = true
                    }
                }
                .opacity(!finished && currentSecretId == secret.id ? 1 : 0)
            }
            SecretQuizFinishedView()
                .opacity(finished ? 1 : 0)
        }
//        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
    }
        
    var currentSecretIndex: Int? {
        secretsModel.secrets.firstIndex { $0.id == currentSecretId }
    }
    
    func getNextSecretId() -> UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let nextIndex = secretsModel.secrets.index(after: currentIndex)
        if nextIndex < secretsModel.secrets.count {
            return secretsModel.secrets[nextIndex].id
        } else {
            return nil
        }
    }
    
    func getPreviousSecretId() -> UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let prevIndex = secretsModel.secrets.index(before: currentIndex)
        if prevIndex >= 0 {
            return secretsModel.secrets[prevIndex].id
        } else {
            return nil
        }
    }
}

struct SecretQuizView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", value: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", value: "showmethemoney"),
        ]
        let secretsModel = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleSecrets))
        Group {
            NavigationView {
                SecretQuizView(currentSecretId:.constant(secretsModel.secrets[0].id))
                    .environmentObject(secretsModel)
            }
            .previewDisplayName("Secret 1/2")
            NavigationView {
                SecretQuizView(currentSecretId: .constant(nil))
                    .environmentObject(secretsModel)
            }
            .previewDisplayName("Invalid secret")
        }
    }
}
