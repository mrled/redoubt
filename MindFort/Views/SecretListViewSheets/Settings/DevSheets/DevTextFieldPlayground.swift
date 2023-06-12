//
//  DevTextFieldPlayground.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-12.
//

import SwiftUI

struct DevTextFieldPlayground: View {
    @State private var passphrase = ""
    @State private var previousMessage = ""
    @State private var message: String? = nil
    @State private var validationWorkItem: DispatchWorkItem?

    var body: some View {
        List {
            Section {
                Button("Clear all", action: clearAll)
            }
            Section {
                Text(message != nil ? message! : "Enter a passphrase...")
            }
            Section("SecureField") {
                SecureField("Passphrase", text: $passphrase, onCommit: validatePassphrase)
                    .keyboardType(.default)
                    .onChange(of: passphrase) { _ in
                        validatePassphrase()
                    }
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
    }
    
    private func validatePassphrase() {
        validationWorkItem?.cancel()
        var tmpPreviousMessage = message ?? ""
        let tmpPassphrase = passphrase
        let item = DispatchWorkItem {
            var tmpMessage = "\(tmpPassphrase.count) letters"
            DispatchQueue.main.async {
                previousMessage = tmpPreviousMessage
                message = tmpMessage
                if (passphrase.count) > 8 {
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
}

struct DevTextFieldPlayground_Previews: PreviewProvider {
    static var previews: some View {
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                DevTextFieldPlayground()
            }
    }
}


