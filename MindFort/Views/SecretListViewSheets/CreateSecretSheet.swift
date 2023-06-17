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
    @EnvironmentObject var secretsModel: SecretsViewModel
    @ObservedObject var keyboardState = KeyboardState()
    @AppStorage(MFAStorage.K.demoMode) var demoMode: Bool = MFAStorage.D.demoMode

    var body: some View {
        VStack {
            
            TextField("Secret name", text: $newSecretName)
                .focused($newSecretFocusOnNameField)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            if demoMode {
                Text("Demonstration mode")
                    .foregroundColor(.red)
            }
            
            SecureField("Passphrase", text: $newSecretValue)
                .keyboardType(.default)
                .onSubmit {
                    // Create the secret with the Enter key if this SecureField IS focused
                    if validSecret {
                        addSecret()
                    }
                }
                .padding()
            
            Button("Add Secret") {
                addSecret()
            }
            // Create a secret with the Enter key if the SecureField is NOT focused
            .keyboardShortcut(.defaultAction)
            .padding()
            .disabled(!validSecret)
            
            // This is empty, so the button will not be visible. We just need it for the keyboardShortcut.
            Button(action: {
                self.isPresentingAddSheet = false
            }) {
                EmptyView()
            }
            .keyboardShortcut(.cancelAction) // Dismiss the sheet with the Escape key
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            H4XX0RC0D3(password: $newSecretValue)
                .padding()
            
            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.async {
                newSecretFocusOnNameField = true
            }
        }
        .navigationBarTitle("Add secret", displayMode: .inline)
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
            let s = try Secret(name: newSecretName, plaintext: newSecretValue)
            return s
        } catch {
            print("newSecret: Error loading items: \(error)")
            return nil
        }
    }
    
    
    /// Add a secret to the viewModel's secret list
    private func addSecret() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        if !validSecret {
            error = "Secret Name and Value must not be empty"
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        if let ns = newSecret {
            secretsModel.addItem(ns)
        } else {
            error = "Could not create secret from input"
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        isPresentingAddSheet = false
        newSecretName = ""
        newSecretValue = ""
        error = nil
        feedbackGenerator.notificationOccurred(.success)
    }
    
    private var validSecret: Bool {
        return !newSecretName.isEmpty && !newSecretValue.isEmpty
    }

}

struct CreateSecretSheet_Previews: PreviewProvider {
    // The Text("Root view") stuff has the .sheet(isPresented:content:)
    // in order to show the view as a sheet overlaid on some background,
    // just like the real app intends.
    static var previews: some View {
        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    CreateSecretSheet(
                        isPresentingAddSheet: .constant(false),
                        newSecretName: .constant("Secure passphrase"),
                        newSecretValue: .constant("password"),
                        error: .constant(nil)
                    )
                }
                .previewDisplayName("Regular password")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    CreateSecretSheet(
                        isPresentingAddSheet: .constant(false),
                        newSecretName: .constant("That XKCD one"),
                        newSecretValue: .constant("correct horse battery staple"),
                        error: .constant(nil)
                    )
                }
                .previewDisplayName("Easter egg: XKCD")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    CreateSecretSheet(
                        isPresentingAddSheet: .constant(false),
                        newSecretName: .constant("AzureDiamond"),
                        newSecretValue: .constant("hunter2"),
                        error: .constant(nil)
                    )
                }
                .previewDisplayName("Easter egg: AzureDiamond")
            
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    // Unfortunately you can't actually mock up the fucking keyboard so this isn't that useful
                    CreateSecretSheet(
                        isPresentingAddSheet: .constant(false),
                        newSecretName: .constant("Secure passphrase"),
                        newSecretValue: .constant("password"),
                        error: .constant("Example error")
                    )
                }
                .previewDisplayName("With error")
        }
    }
}
