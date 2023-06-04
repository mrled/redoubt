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
    @Binding var notificationsAllowed: Bool
    var showControlPanel: Bool = false
    var showOnboarding: Bool = false
    @State private var selectedSecretId: UUID? = nil
    @State private var quizCurrentSecretId: UUID? = nil
    @State private var isPresentingAddSheet = false
    @State private var isPresentingSettingsSheet = false
    @State private var isPresentingAcknowledgementsSheet = false
    @State private var isPresentingOnboardingSheet = false
    @State private var isPresentingControlPanelSheet = false
    @State private var isPresentingDevToDoSheet = false
    @State private var newSecretName = ""
    @State private var newSecretValue = ""
    @State private var error: String?
    @State private var toolbarImageSize: CGSize = .zero
    @FocusState private var newSecretFocusOnNameField: Bool
    
    var body: some View {
        NavigationView {
            List {
                if secretsModel.secrets.count > 0 {
                    Section() {
                        NavigationLink(
                            destination: SecretQuizView(currentSecretId: $quizCurrentSecretId).environmentObject(secretsModel),
                            tag: OpenAction.startQuiz,
                            selection: $openAction
                        ) {
                            Text("Quiz now")
                        }
                    }
                    Section() {
                        ForEach(Array(secretsModel.secrets.enumerated()), id: \.element.id) { index, secret in
                            NavigationLink(
                                destination:
                                    SecretDetailView(currentSecretId: $selectedSecretId)
                                    .environmentObject(secretsModel),
                                tag: secret.id,
                                selection: $selectedSecretId
                            ) {
                                Text(secret.name)
                            }
                        }
                        .onDelete(perform: removeSecrets)
                    }
                } else {
                    Text("Press the + button to add a secret")
                        .foregroundColor(.gray)
                }
            }
            .navigationBarTitle("Secrets")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: { isPresentingSettingsSheet = true }) {
                        ZStack {
                            Image(systemName: "gear")
                            /// Show a badge if notification access has not been granted
                            if !notificationsAllowed {
                                Circle()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(Color.red)
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                    if showOnboarding {
                        ZStack {
                            /// We define an invisible button with the same image only to measure its size
                            Button(action: { isPresentingOnboardingSheet = true }) {
                                Image(systemName: "play")
                                    .modifier(ReadSize(size: $toolbarImageSize))
                                    .opacity(0)
                            }
                            /// We apply that size to the button we want to display
                            /// Our ShimmeringSystemImage view doesn't behave the same way a regular Image does;
                            /// it gets created very small, and also gets a distorted aspect ratio.
                            /// This hack fixes that.
                            Button(action: { isPresentingOnboardingSheet = true }) {
                                ShimmeringSystemImage(systemName: "play")
                                    .frame(width: toolbarImageSize.width, height: toolbarImageSize.height)
                            }
                        }
                        /// It can be useful to see the correct size when debugging
//                        Button(action: { isPresentingOnboardingSheet = true }) {
//                            Image(systemName: "play")
//                        }
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
                SettingsSheet(notificationsAllowed: $notificationsAllowed)
                    .environmentObject(notificationsModel)
            }
            .sheet(isPresented: $isPresentingOnboardingSheet) {
                OnboardingSheet(isPresentingOnboardingSheet: $isPresentingOnboardingSheet)
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
        .onAppear(perform: {
            for secret in secretsModel.secrets {
                CustomLogger.secretIds(message: " - SecretListView onAppear: \(secret.id)")
            }
            NotificationManager.shared.requestPermission { granted in
                notificationsAllowed = granted
            }
        })
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
        let secretsModelTwoSecrets = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleSecrets))
        let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
        Group {
            SecretListView(openAction: .constant(.home), notificationsAllowed: .constant(true))
                .environmentObject(secretsModelTwoSecrets)
                .environmentObject(notificationsViewModel)
                .previewDisplayName("Default values")
            SecretListView(openAction: .constant(.home), notificationsAllowed: .constant(true), showControlPanel: true)
                .environmentObject(secretsModelTwoSecrets)
                .environmentObject(notificationsViewModel)
                .previewDisplayName("showControlPanel")
            SecretListView(openAction: .constant(.home), notificationsAllowed: .constant(true))
                .environmentObject(SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray([])))
                .environmentObject(notificationsViewModel)
                .previewDisplayName("No secrets")
            SecretListView(
                openAction: .constant(.home),
                notificationsAllowed: .constant(true),
                showControlPanel: false,
                showOnboarding: true
            )
            .environmentObject(secretsModelTwoSecrets)
            .environmentObject(notificationsViewModel)
            .previewDisplayName("Show onboarding")
        }
    }
}
