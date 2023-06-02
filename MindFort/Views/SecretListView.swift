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
    @Binding var openAction: OpenAction?
    var showControlPanel: Bool = false
    @State private var isPresentingAddSheet = false
    @State private var isPresentingSettingsSheet = false
    @State private var isPresentingAcknowledgementsSheet = false
    @State private var isPresentingControlPanelSheet = false
    @State private var isPresentingDevToDoSheet = false
    @State private var newSecretName = ""
    @State private var newSecretValue = ""
    @State private var error: String?
    @State private var notificationsAllowed: Bool = false
    @FocusState private var newSecretFocusOnNameField: Bool
    
    var body: some View {
        NavigationView {
            List {
                if secretsModel.secrets.count > 0 {
                    Section() {
                        NavigationLink(destination: QuizView().environmentObject(secretsModel), tag: OpenAction.startQuiz, selection: $openAction) {
                                Text("Quiz now")
                            }
//                        NavigationLink(destination: QuizView().environmentObject(secretsModel)) {
//                                Text("Quiz now")
//                            }
                    }
                    Section() {
                        ForEach(Array(secretsModel.secrets.enumerated()), id: \.element.id) { index, secret in
                            NavigationLink(destination: SecretDetailView(secret: secret, index: index)
                                .environmentObject(secretsModel)) {
                                    Text(secret.name)
                                }
                        }
                        .onDelete(perform: removeSecrets)
                    }
                } else {
                    Text("Click the + button to add a secret")
                }
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
                        Button(action: { isPresentingDevToDoSheet = true }) {
                            Image(systemName: "checklist.unchecked")
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
                    .environmentObject(notificationsModel)
            }
            .sheet(isPresented: $isPresentingDevToDoSheet) {
                DeveloperToDoSheet()
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
        let secretsModelTwoSecrets = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(secrets: exampleSecrets))
        let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
        Group {
            SecretListView(openAction: .constant(.home))
                .environmentObject(secretsModelTwoSecrets)
                .environmentObject(notificationsViewModel)
                .previewDisplayName("Default values")
            SecretListView(openAction: .constant(.home), showControlPanel: true)
                .environmentObject(secretsModelTwoSecrets)
                .environmentObject(notificationsViewModel)
                .previewDisplayName("showControlPanel")
            SecretListView(openAction: .constant(.home))
                .environmentObject(SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(secrets: [])))
                .environmentObject(notificationsViewModel)
                .previewDisplayName("No secrets")
        }
    }
}
