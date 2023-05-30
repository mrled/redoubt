//
//  CreateSecretSheet.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import SwiftUI

struct CreateSecretSheet: View {
    @Binding var isPresentingAddSheet: Bool
    @Binding var newSecretName: String
    @Binding var newSecretValue: String
    @Binding var error: String?
    @FocusState private var newSecretFocusOnNameField: Bool
    @EnvironmentObject var viewModel: MindFortViewModel
    
    // add the rest of the properties and functions here...

    var body: some View {
        VStack {
            Text(newSecretTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            Spacer()
            TextField("Secret name", text: $newSecretName)
                .focused($newSecretFocusOnNameField)
                .padding()
            SecureField("Passphrase", text: $newSecretValue)
                .keyboardType(.default)
                .padding()
            Button("Add Secret") {
                addSecret()
                isPresentingAddSheet = false
                newSecretName = ""
                newSecretValue = ""
                error = nil
            }
            .padding()
            .disabled(!validSecret)
            Spacer()
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                Spacer()
            }
            Text("H4XX0R C0D3")
                .font(.headline)
            Text(h4xx0rc0d3)
                .font(.system(size: 14, design: .monospaced))
                .padding()
            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.async {
                newSecretFocusOnNameField = true
            }
        }
    }
    
    /// The title of the new secret sheet
    private var newSecretTitle: String {
        if let newSecret {
            if newSecret.name.count > 0 {
                print("New secret has a name! It's: '\(newSecret.name)'")
                return newSecret.name
            }
        }
        return "New Secret"
    }
    
    /// A secret created from $newSecretName / $newSecretValue
    private var newSecret: Secret? {
        do {
            let s = try Secret(name: newSecretName, value: newSecretValue)
            return s
        } catch {
            print("newSecret: Error loading items: \(error)")
            return nil
        }
    }
    
    /// H4XX0R C0D3
    /// This is:
    ///  - the hash block of the new secret under normal circumstances
    ///  - a placeholder if the new secret is empty
    ///  - an easter egg if you enter one of the famous passwords
    private var h4xx0rc0d3: String {
        if let newSecret {
            if let newVal = newSecret.value {
                if let easterEggCode = easterEggPasswords[newVal] {
                    return groupCharacters(string: easterEggCode.joined(separator: ""), perLine: 4)
                } else if newVal.count > 0 {
                    return prettyHashBlock(digest: newSecret.digest, perLine: 4)
                }
            }
        }
        return placeholderHashBlock(perLine: 4)
    }
    
    /// Add a secret to the viewModel's secret list
    private func addSecret() {
        if !validSecret {
            error = "Secret Name and Value must not be empty"
            return
        }
        if let ns = newSecret {
            viewModel.addItem(ns)
        } else {
            print("addSecret: Could not add an empty/invalid secret")
        }
    }
    
    private var validSecret: Bool {
        return !newSecretName.isEmpty && !newSecretValue.isEmpty
    }

}

struct CreateSecretSheet_Previews: PreviewProvider {
    // Let's show off some easter eggs :)
    static var previews: some View {
        CreateSecretSheet(
            isPresentingAddSheet: .constant(false),
            newSecretName: .constant("Secure passphrase"),
            newSecretValue: .constant("password"),
            error: .constant(nil)
        )
        CreateSecretSheet(
            isPresentingAddSheet: .constant(false),
            newSecretName: .constant("That XKCD one"),
            newSecretValue: .constant("correct horse battery staple"),
            error: .constant(nil)
        )
        CreateSecretSheet(
            isPresentingAddSheet: .constant(false),
            newSecretName: .constant("AzureDiamond"),
            newSecretValue: .constant("hunter2"),
            error: .constant(nil)
        )
    }
}
