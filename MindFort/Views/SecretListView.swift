//
//  SecretListView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI

struct SecretListView: View {
    @EnvironmentObject var secretsModel: SecretsViewModel
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    var showControlPanel: Bool = false
    @State private var isPresentingAddSheet = false
    @State private var isPresentingSettingsSheet = false
    @State private var isPresentingAcknowledgementsSheet = false
    @State private var isPresentingControlPanelSheet = false
    @State private var newSecretName = ""
    @State private var newSecretValue = ""
    @State private var error: String?
    @State private var notificationsAllowed: Bool = false
    @FocusState private var newSecretFocusOnNameField: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(secretsModel.secrets.enumerated()), id: \.element.id) { index, secret in
                    NavigationLink(destination: SecretDetailView(secret: secret, index: index)
                        .environmentObject(secretsModel)) {
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
                    if showControlPanel {
                        Button(action: { isPresentingControlPanelSheet = true }) {
                            Image(systemName: "slider.horizontal.3")
                        }
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
                .environmentObject(secretsModel)
            }
            .sheet(isPresented: $isPresentingSettingsSheet) {
                SettingsSheet()
                    .environmentObject(notificationsModel)
            }
            .sheet(isPresented: $isPresentingAcknowledgementsSheet) {
                AboutSheet()
            }
            .sheet(isPresented: $isPresentingControlPanelSheet) {
                ControlPanelSheet()
            }
            .onAppear {
                secretsModel.loadItems()
                notificationsModel.load()
            }
        }
    }
    
    func removeSecrets(at offsets: IndexSet) {
        secretsModel.secrets.remove(atOffsets: offsets)
    }
}

struct SecretListView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", value: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", value: "showmethemoney"),
        ]
        let secretsModel = SecretsViewModel(dataLoader: PreviewDataLoader(secrets: exampleSecrets))
        let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromLiterals(schedules: []))
        Group {
            SecretListView()
                .environmentObject(secretsModel)
                .environmentObject(notificationsViewModel)
                .previewDisplayName("Default values")
            SecretListView(showControlPanel: true)
                .environmentObject(secretsModel)
                .environmentObject(notificationsViewModel)
                .previewDisplayName("showControlPanel")
        }
    }
}
