//
//  HashedSecretView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI

struct HashedSecretView: View {
    @ObservedObject var viewModel = HashedSecretViewModel()
    @State private var isPresentingAddSheet = false
    @State private var newSecretName = ""
    @State private var newSecretValue = ""
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.secrets) { secret in
                    NavigationLink(destination: SecretDetailView(secret: secret)) {
                        Text(secret.name)
                    }
                }
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
            TextField("Secret Name?", text: $newSecretName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Secret Value", text: $newSecretValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
            }
            Button("Add Secret") {
                addSecret()
                isPresentingAddSheet = false
                newSecretName = ""
                newSecretValue = ""
                error = nil
            }
            .padding()
            .disabled(!validSecret)
        }
        .padding()
        .frame(width: 300, height: 200) // Adjust size as needed
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 4)
        .frame(minWidth: 300, minHeight: 200) // Set a minimum size for the sheet
    }
    
    private func addSecret() {
        if !validSecret {
            error = "Secret Name and Value must not be empty"
            return
        }

        do {
            let newSecret = try HashedSecret(name: newSecretName, value: newSecretValue)
            viewModel.addItem(newSecret)
        } catch {
            print("Error loading items: \(error)")
        }
    }
    
    private var validSecret: Bool {
        return !newSecretName.isEmpty && !newSecretValue.isEmpty
    }
    
    func removeSecrets(at offsets: IndexSet) {
        viewModel.secrets.remove(atOffsets: offsets)
    }
}

struct SecretDetailView: View {
    let secret: HashedSecret
    
    var body: some View {
        VStack {
            Text("Secret Name: \(secret.name)")
            Text("Hash: \(secret.h4xx0rcode)")
        }
        .navigationBarTitle(secret.name)
    }
}

//struct HashedSecretView_Previews: PreviewProvider {
//    static var previews: some View {
//        HashedSecretView(secrets: .constant([
//            unwrappedValue(HashedSecret.fromValue("password", name: "Secure passphrase")),
//            unwrappedValue(HashedSecret.fromValue("showmethemoney", name: "Bitcoin wallet passphrase")),
//        ]))
//    }
//}
