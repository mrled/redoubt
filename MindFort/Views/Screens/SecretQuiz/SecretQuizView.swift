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
    
    @EnvironmentObject var secretsVm: SecretsViewModel
    
    var body: some View {
        ZStack {
            ForEach(secretsVm.secrets.indices, id: \.self) { index in
                let secret = self.$secretsVm.secrets[index]
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
                .opacity(!finished && currentSecretId == secret.id ? 1 : 0)
            }
            SecretQuizFinishedView(finished: $finished)
                .opacity(finished ? 1 : 0)
        }
//        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
        .onAppear() {
            /// Set the initial values
            currentSecretId = secretsVm.secrets[0].id
            activeView = secretsVm.secrets[0].id
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DemoNavbarToolbarButton()
            }
        }
    }
        
    var currentSecretIndex: Int? {
        secretsVm.secrets.firstIndex { $0.id == currentSecretId }
    }
    
    func getNextSecretId() -> UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let nextIndex = secretsVm.secrets.index(after: currentIndex)
        if nextIndex < secretsVm.secrets.count {
            return secretsVm.secrets[nextIndex].id
        } else {
            return nil
        }
    }
    
    func getPreviousSecretId() -> UUID? {
        guard let currentIndex = currentSecretIndex else { return nil }
        let prevIndex = secretsVm.secrets.index(before: currentIndex)
        if prevIndex >= 0 {
            return secretsVm.secrets[prevIndex].id
        } else {
            return nil
        }
    }
}

struct SecretQuizView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", plaintext: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
        ]
        let exampleCollection = SecretCollection(secrets: exampleSecrets, regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
        let secretsPreviewVm = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollection))
        Group {
            NavigationView {
                SecretQuizView(currentSecretId:.constant(secretsPreviewVm.secrets[0].id))
                    .environmentObject(secretsPreviewVm)
            }
            .previewDisplayName("Secret 1/2")
            NavigationView {
                SecretQuizView(currentSecretId: .constant(nil))
                    .environmentObject(secretsPreviewVm)
            }
            .previewDisplayName("Invalid secret")
        }
    }
}
