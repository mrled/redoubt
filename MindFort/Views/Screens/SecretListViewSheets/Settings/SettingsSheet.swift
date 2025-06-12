//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI
import Foundation


enum VisualizationMode: String, Codable, CaseIterable, Identifiable {
    case Sha512
    
    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .Sha512: return "SHA512 hash"
        }
    }
}


struct RegularIntervalScheduleControls: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    
    var body: some View {
        Group {
            if secretsVm.regularIntervalNotifications.count > 0 {
                // WARNING: you cannot ForEach over a bound array and bind each element to a new child view!!!
                // If you do, Xcode will give you the most insane errors, and put them on the wrong line.
                // Instead you have to ForEach over indices, like this:
                ForEach(secretsVm.regularIntervalNotifications.indices, id: \.self) { index in
                    let dateBinding = Binding<Date>(
                        get: {
                            Calendar.current.date(from: secretsVm.regularIntervalNotifications[index]) ?? Date()
                        },
                        set: {
                            secretsVm.regularIntervalNotifications[index] = Calendar.current.dateComponents([.hour, .minute], from: $0)
                        }
                    )
                    TimePickerExpandable(date: dateBinding)
                }
                .onDelete(perform: removeScheduleTime)
            } else {
                Text("No time set, will not send notification")
                    .foregroundColor(.gray)
            }
            Button("Add a time", action: addScheduleTime)
        }
    }
     
    func addScheduleTime() {
        secretsVm.regularIntervalNotifications.append(
            Calendar.current.dateComponents([.hour, .minute], from: Date())
        )
    }

    func removeScheduleTime(at offsets: IndexSet) {
        for index in offsets {
            secretsVm.regularIntervalNotifications.remove(at: index)
        }
    }
}


struct SpacedRepetitionScheduleControls: View {
    @EnvironmentObject var secretsVm: SecretsViewModel

    var body: some View {
        Group {
            Text("MindFort will prompt you for passwords at these intervals")
                .foregroundColor(.gray)
            ForEach(secretsVm.spacedRepetitionCategories) { category in
                Text("    \(category.name)")
                    .foregroundColor(.gray)
            }
            // TODO: show the time the notification will be delivered
            // TODO: allow setting a daily time range like 9-5
        }
    }
}


struct ScheduleControls: View {
    @Binding var notificationsAllowed: Bool
    @AppStorage(MFAStorage.K.scheduleType) var scheduleType: ScheduleType = MFAStorage.D.scheduleType

    var body: some View {
        Section("Schedule") {
            if notificationsAllowed {
                Picker(selection: $scheduleType, label: Text("Schedule type")) {
                    ForEach(ScheduleType.allCases) { schedType in
                        Text(schedType.description).tag(schedType)
                    }
                }
                .onChange(of: scheduleType) { newValue in
                    // TODO: cancel all notifications from previous selection, add notifications from new selection
                    switch newValue {
                    case .disabled:
                        break
                    case .daily:
                        break
                    case .spacedRepetition:
                        break
                    }
                }

                switch scheduleType {
                case .disabled:
                    EmptyView()
                case .daily:
                    RegularIntervalScheduleControls()
                case .spacedRepetition:
                    SpacedRepetitionScheduleControls()
                }
            } else {
                Text("To schedule reminders, please enable notifications in Settings.")
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        RowItemUrlWithIcon(title: "Open Settings", systemImageName: "gear", destination: url)
                    }
                }
            }
        }
    }
}


struct SettingsControls: View {
    @Binding var showOnboarding: Bool
    @Binding var showDeveloperOptions: Bool
    @Binding var enableEasterEggs: Bool
    @Binding var visualizationMode: VisualizationMode
    @Binding var demoMode: Bool
    var body: some View {
        Section("Settings") {
            // Not sure if it's the Toggles or what, but the spacing doesn't match RowItemWithIcon.
            // Just make them all HStack{Image, Text} and they look the same.
            Toggle(isOn: $showOnboarding) {
                // is a RowItemWithIcon except the Icon is a ShimmeringSystemImage
                HStack {
                    ShimmeringSystemImage(systemName: "play")
                        .frame(width: 32, height: 32)
                    Text("Show the onboarding button")
                }
            }
            Toggle(isOn: $enableEasterEggs) {
                HStack {
                    Image(systemName: "sparkles")
                        .frame(width: 32, height: 32)
                    Text("Enable easter eggs")
                }
            }
            HStack {
                Image(systemName: "sparkles.tv")
                    .frame(width: 32, height: 32)
                Picker(selection: $visualizationMode, label: Text("Visualization type")) {
                    ForEach(VisualizationMode.allCases) { possibleVizMode in
                        Text(possibleVizMode.description).tag(possibleVizMode)
                    }
                }
            }
            Toggle(isOn: $showDeveloperOptions) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 32, height: 32)
                    Text("Show developer options")
                }
            }
            NavigationLink(destination: DemoModeSheet(isPresentingDemoMode: .constant(false))) {
                HStack {
                    Image(systemName: "tv")
                        .frame(width: 32, height: 32)
                    if demoMode {
                        Text("Demo mode (currently enabled)")
                    } else {
                        Text("Demo mode (currently disabled)")
                    }
                }
            }
        }
    }
}

struct DeveloperOptions: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    
    var body: some View {
        Section("Developer") {
            NavigationLink(destination: DevNotifications()) {
                Text("Notifications debugger")
            }
            NavigationLink(destination: DevHapticPlayground()) {
                Text("Haptic playground")
            }
            if secretsVm.secrets.isEmpty {
                Text("Add a secret to enable the text field playground")
            } else {
                NavigationLink(destination: DevTextFieldPlayground(currentSecretId: .constant(secretsVm.secrets[0].id))) {
                    Text("Text field playground")
                }
            }
        }
    }
}

struct SettingsSheet: View {
    @Binding var notificationsAllowed: Bool
    @AppStorage(MFAStorage.K.enableEasterEggs) var enableEasterEggs: Bool = MFAStorage.D.enableEasterEggs
    @AppStorage(MFAStorage.K.showDeveloperOptions) var showDeveloperOptions: Bool = MFAStorage.D.showDeveloperOptions
    @AppStorage(MFAStorage.K.scheduleType) var scheduleType: ScheduleType = MFAStorage.D.scheduleType
    @AppStorage(MFAStorage.K.showOnboarding) var showOnboarding: Bool = MFAStorage.D.showOnboarding
    @AppStorage(MFAStorage.K.visualizationMode) var visualizationMode: VisualizationMode = MFAStorage.D.visualizationMode
    @AppStorage(MFAStorage.K.demoMode) var demoMode: Bool = MFAStorage.D.demoMode
    @State private var scheduleEveryXDays: Int = 1

    var body: some View {
        VStack {
            NavigationView {
                List {
                    ScheduleControls(notificationsAllowed: $notificationsAllowed)
                    SettingsControls(
                        showOnboarding: $showOnboarding,
                        showDeveloperOptions: $showDeveloperOptions,
                        enableEasterEggs: $enableEasterEggs,
                        visualizationMode: $visualizationMode,
                        demoMode: $demoMode
                    )
                    Section("About") {
                        NavigationLink(destination: AboutSheet()) {
                            Text("About MindFort")
                        }
                        NavigationLink(destination: Roadmap()) {
                            Text("Development Roadmap")
                        }
                    }
                    if showDeveloperOptions {
                        DeveloperOptions()
                    }
                }
                .navigationBarTitle("Settings", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DemoNavbarToolbarButton()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", plaintext: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", plaintext: "showmethemoney"),
        ]
        let exampleCollection = SecretCollection(secrets: exampleSecrets, regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
        let secretsPreviewVmTwoSecretsNoSchedules = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleCollection))

        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(secretsPreviewVmTwoSecretsNoSchedules)
            }
            .previewDisplayName("Simple, no schedules")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(secretsPreviewVmTwoSecretsNoSchedules)
                }
                .previewDisplayName("Simple, one schedule")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(false))
                        .environmentObject(secretsPreviewVmTwoSecretsNoSchedules)
                }
                .previewDisplayName("Notifications not allowed")
        }
    }
}
