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
//    @State private var isFlipped: Bool = false
    @State private var finished: Bool = false
    
    /// We have to do something kind of unusual to control which child SecretQuizInnerView should focus its passphrase field
    /// 1. Right here, initialize activeView (this @FocuState) as a UUID?
    /// 2. In this view, set activeView whenever we change currentSecretId, as they represent the same data just in different formats; make sure to set both initial state and every time a password is entered successfully
    /// 3. In the child SecretQuizInnerView views, add a binding like var activeView: FocusState<UUID?>.Binding
    /// 4. In this view, when we create the child views, pass activeView: $activeView
    /// 5. In the child SecretQuizInnerView views, set .focused(activeView, equals: secret.id) on the field we want to have focus.
    /// See also:
    /// - https://developer.apple.com/forums/thread/682448
    @FocusState private var activeView: UUID?
    
    @EnvironmentObject var secretsModel: SecretsViewModel
    
    var body: some View {
        ZStack {
            ForEach(secretsModel.secrets) { secret in
                SecretQuizInnerView(secret: secret, currentSecretId: $currentSecretId, activeView: $activeView) {
                    /// This is a callback function that the child view will run when the passphrase is entered successfully
                    /// Note that it's only run AFTER the passphrase is entered correctly, meaning that we have to use the .onAppear below to set INITIAL values.
                    if let nextSecretId = getNextSecretId() {
                        currentSecretId = nextSecretId
                        activeView = nextSecretId
                    } else {
                        finished = true
                        currentSecretId = nil
                        activeView = nil
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        DispatchQueue.global(qos: .userInitiated).async {
                            for _ in 0..<3 {
                                /// Note that haptic feedback should be initiated from the main thread only!
                                DispatchQueue.main.async {
                                    feedbackGenerator.notificationOccurred(.success)
                                }
                                /// But we sleep on the background queue
                                usleep(300000) // sleep for 300ms
                            }
                        }
                    }
                }
                .environmentObject(secretsModel)
                .opacity(!finished && currentSecretId == secret.id ? 1 : 0)
            }
            SecretQuizFinishedView(finished: $finished)
                .environmentObject(secretsModel)
                .opacity(finished ? 1 : 0)
        }
//        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
        .onAppear() {
            /// Set the initial values
            currentSecretId = secretsModel.secrets[0].id
            activeView = secretsModel.secrets[0].id
        }
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
