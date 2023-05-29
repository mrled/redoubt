//
//  SecretListView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI

struct SecretListView: View {
    @EnvironmentObject var viewModel: SecretListViewModel
    @State private var isPresentingAddSheet = false
    @State private var newSecretName = ""
    @State private var newSecretValue = ""
    @State private var error: String?
    @FocusState private var newSecretFocusOnNameField: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(viewModel.secrets.enumerated()), id: \.element.id) { index, secret in
                    NavigationLink(destination: SecretDetailView(secret: secret, index: index)
                        .environmentObject(viewModel)) {
                        Text(secret.name)
                    }
                }
                .onDelete(perform: removeSecrets)
            }
            .navigationBarTitle("Secrets")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                createSecretSheet
            }
            .onAppear {
                viewModel.loadItems()
            }
        }
    }
    
    private var createSecretSheet: some View {
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
            Text(newSecretHashBlockOrPlaceholder)
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
    
    /// The digest of the newSecret, or a placeholder value
    private var newSecretHashBlockOrPlaceholder: String {
        if let newSecret {
            if newSecret.value?.count ?? 0 > 0 {
                print("New Secret has value \(newSecret.value ?? "<empty>")")
                return prettyHashBlock(digest: newSecret.digest, perLine: 4)
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
    
    func removeSecrets(at offsets: IndexSet) {
        viewModel.secrets.remove(atOffsets: offsets)
    }
}

struct SecretListView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", value: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", value: "showmethemoney"),
        ]
        let viewModel = SecretListViewModel(dataLoader: PreviewDataLoader(secrets: exampleSecrets))
        return SecretListView()
            .environmentObject(viewModel)
    }
}
