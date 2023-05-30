//
//  SecretListView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI

struct SecretListView: View {
    @EnvironmentObject var viewModel: MindFortViewModel
    @State private var isPresentingAddSheet = false
    @State private var isPresentingSettingsSheet = false
    @State private var isPresentingAcknowledgementsSheet = false
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
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: { isPresentingSettingsSheet = true }) {
                        Image(systemName: "gear")
                    }
                    Button(action: { isPresentingAcknowledgementsSheet = true }) {
                        Image(systemName: "info.square")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                CreateSecretSheet(
                    isPresentingAddSheet: $isPresentingAddSheet,
                    newSecretName: $newSecretName,
                    newSecretValue: $newSecretValue,
                    error: $error
                )
                .environmentObject(viewModel)
            }
            .sheet(isPresented: $isPresentingSettingsSheet) {
                SettingsSheet()
            }
            .sheet(isPresented: $isPresentingAcknowledgementsSheet) {
                AboutSheet()
            }
            .onAppear {
                viewModel.loadItems()
            }
        }
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
        let viewModel = MindFortViewModel(dataLoader: PreviewDataLoader(secrets: exampleSecrets))
        return SecretListView()
            .environmentObject(viewModel)
    }
}
