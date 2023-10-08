//
//  SecretListView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI

struct SecretListView: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    @EnvironmentObject var notificationsVm: NotificationsViewModel
    @Binding var openAction: OpenAction?
    @Binding var notificationsAllowed: Bool
    @State private var selectedSecretId: UUID? = nil
    @State private var quizCurrentSecretId: UUID? = nil
    @State private var isPresentingAddSheet = false
    @State private var isPresentingSettingsSheet = false
    @State private var isPresentingOnboardingSheet = false
    @State private var newSecretName = ""
    @State private var newSecretValue = ""
    @State private var error: String?
    @State private var toolbarImageSize: CGSize = .zero
    @FocusState private var newSecretFocusOnNameField: Bool
    @AppStorage(MFAStorage.K.showOnboarding) var showOnboarding: Bool = MFAStorage.D.showOnboarding
    @AppStorage(MFAStorage.K.onboardingHasShownOnce) var onboardingHasShownOnce: Bool = MFAStorage.D.onboardingHasShownOnce
    @AppStorage(MFAStorage.K.demoMode) private var demoMode: Bool = MFAStorage.D.demoMode

    var body: some View {
        NavigationView {
            List {
                if secretsVm.secrets.count > 0 {
                    Section() {
                        NavigationLink(
                            destination: SecretQuizView(currentSecretId: $quizCurrentSecretId),
                            tag: OpenAction.startQuiz,
                            selection: $openAction
                        ) {
                            Text("Quiz now")
                        }
                    }
                    Section() {
                        ForEach(Array(secretsVm.secrets.enumerated()), id: \.element.id) { index, secret in
                            NavigationLink(
                                destination: SecretDetailView(currentSecretId: $selectedSecretId),
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
                    DemoNavbarToolbarButton()
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
            }
            .sheet(isPresented: $isPresentingSettingsSheet) {
                SettingsSheet(notificationsAllowed: $notificationsAllowed)
            }
            .sheet(isPresented: $isPresentingOnboardingSheet) {
                OnboardingSheet(isPresentingOnboardingSheet: $isPresentingOnboardingSheet)
            }
            .onAppear {
                secretsVm.loadItems()
                notificationsVm.load()
                if !onboardingHasShownOnce {
                    isPresentingOnboardingSheet = true
                }
            }
        }
        .onChange(of: openAction) { newOpenAction in
            // We have to do this in onChange(of:), not onAppear(perform:), due to something about view lifecycle and @Binding properties
            if newOpenAction != .home {
                dismissAllSheets()
            }
        }
        .onAppear(perform: {
            for secret in secretsVm.secrets {
                CustomLogger.secretIds(message: " - SecretListView onAppear: \(secret.id)")
            }
            NotificationManager.shared.requestPermission { granted in
                notificationsAllowed = granted
            }
        })
    }
    
    func removeSecrets(at offsets: IndexSet) {
        secretsVm.secrets.remove(atOffsets: offsets)
    }
    
    func dismissAllSheets() {
        isPresentingAddSheet = false
        isPresentingSettingsSheet = false
        isPresentingOnboardingSheet = false
    }
}

struct SecretListView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", plaintext: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
        ]
        let exampleCollectionTwoSecrets = SecretCollection(secrets: exampleSecrets, regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
        let secretsPreviewVmTwoSecrets = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollectionTwoSecrets))
        let exampleCollectionZeroSecrets = SecretCollection(secrets: [], regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
        let secretsPreviewVmZeroSecrets = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollectionZeroSecrets))
        let notificationsPreviewVm = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
        Group {
            SecretListView(openAction: .constant(.home), notificationsAllowed: .constant(true))
                .environmentObject(secretsPreviewVmTwoSecrets)
                .environmentObject(notificationsPreviewVm)
                .previewDisplayName("Default values")
            SecretListView(openAction: .constant(.home), notificationsAllowed: .constant(true))
                .environmentObject(secretsPreviewVmZeroSecrets)
                .environmentObject(notificationsPreviewVm)
                .previewDisplayName("No secrets")
            SecretListView(
                openAction: .constant(.home),
                notificationsAllowed: .constant(true),
                showOnboarding: true
            )
            .environmentObject(secretsPreviewVmTwoSecrets)
            .environmentObject(notificationsPreviewVm)
            .previewDisplayName("Show onboarding")
        }
    }
}
