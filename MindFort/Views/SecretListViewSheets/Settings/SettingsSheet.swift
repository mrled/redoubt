//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI
import Foundation


enum VisualizationMode: String, Codable, CaseIterable, Identifiable {
    case RawArgon2
    case Sha512Argon2
    
    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .RawArgon2: return "Raw Argon2 (ugly)"
        case .Sha512Argon2: return "SHA512 hash of Argon2"
        }
    }
}


struct RegularIntervalScheduleControls: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    
    var body: some View {
        Group {
            if notificationsModel.regularIntervalEntries.count > 0 {
                // WARNING: you cannot ForEach over a bound array and bind each element to a new child view!!!
                // If you do, Xcode will give you the most insane errors, and put them on the wrong line.
                // Instead you have to ForEach over indices, like this:
                ForEach(notificationsModel.regularIntervalEntries.indices, id: \.self) { index in
                    let dateBinding = Binding<Date>(
                        get: {
                            Calendar.current.date(from: notificationsModel.regularIntervalEntries[index]) ?? Date()
                        },
                        set: {
                            notificationsModel.regularIntervalEntries[index] = Calendar.current.dateComponents([.hour, .minute], from: $0)
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
        notificationsModel.regularIntervalEntries.append(
            Calendar.current.dateComponents([.hour, .minute], from: Date())
        )
    }

    func removeScheduleTime(at offsets: IndexSet) {
        for index in offsets {
            notificationsModel.regularIntervalEntries.remove(at: index)
        }
    }
}


//struct SpacedRepetitionScheduleControls: View {
//    @AppStorage("spacedRepetitionIntervalDays") var spacedRepetitionIntervalDays: Int = 1
//    @AppStorage("spacedRepetitionIntervalsPerDay") var spacedRepetitionIntervalsPerDay: Int = 1
//
//    var body: some View {
//        Group {
//            Stepper(value: $spacedRepetitionIntervalDays, in: 1...7) {
//                Text(spacedRepetitionIntervalText)
//            }
//            TimeRangePicker()
//            // TODO: show the time the notification will be delivered
//            // TODO: if $spacedRepetitionIntervalDays == 1, allow more than one time, and show an Add button at the bottom.
//        }
//    }
//
//    var spacedRepetitionIntervalText: String {
//        if spacedRepetitionIntervalDays > 1 {
//            return "Every \(spacedRepetitionIntervalDays) days"
//        } else if spacedRepetitionIntervalDays == 1 {
//            return "Every \(spacedRepetitionIntervalDays) day"
//        } else {
//            if spacedRepetitionIntervalsPerDay == 0 {
//                return "Never"
//            } else if spacedRepetitionIntervalsPerDay == 1 {
//                return "Once every day"
//            } else if spacedRepetitionIntervalsPerDay == 2 {
//                return "Twice every day"
//            } else {
//                return "\(spacedRepetitionIntervalsPerDay) times per day"
//            }
//        }
//    }
//}


struct ScheduleControls: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @Binding var notificationsAllowed: Bool
    @AppStorage(MFAStorage.K.scheduleEnabled) var scheduleEnabled: Bool = MFAStorage.D.scheduleEnabled
    @AppStorage(MFAStorage.K.scheduleType) var scheduleType: ScheduleType = MFAStorage.D.scheduleType

    var body: some View {
        Section("Schedule") {
            if notificationsAllowed {
                Toggle(isOn: $scheduleEnabled) {
                    Text("Enable scheduled reminders")
                }
                .disabled(!notificationsAllowed)
                Group {
                    Picker(selection: $scheduleType, label: Text("Schedule type")) {
                        ForEach(ScheduleType.allCases) { schedType in
                            Text(schedType.description).tag(schedType)
                        }
                    }
                    if scheduleType == .daily {
                        RegularIntervalScheduleControls()
                            .environmentObject(notificationsModel)
                    }
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
    
//    /// Combine the hours-and-minutes-only .scheduleTimes.dateComponents
//    /// with the days/weeks/months controlled by scheduleEveryXDays
//    var scheduleItems: [DateComponents] {
//        if !scheduleEnabled {
//            return []
//        }
//        let result: [DateComponents] = []
//        for time in scheduleTimes {
//            var component = DateComponents(
//        }
//        return result
//    }
}


struct SettingsControls: View {
    @Binding var showOnboarding: Bool
    @Binding var enableEasterEggs: Bool
    @Binding var visualizationMode: VisualizationMode
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
                Image(systemName: "display")
                    .frame(width: 32, height: 32)
                Picker(selection: $visualizationMode, label: Text("Visualization type")) {
                    ForEach(VisualizationMode.allCases) { possibleVizMode in
                        Text(possibleVizMode.description).tag(possibleVizMode)
                    }
                }
            }
        }
    }
}

struct SettingsSheet: View {
    @Binding var notificationsAllowed: Bool
    @AppStorage(MFAStorage.K.enableEasterEggs) var enableEasterEggs: Bool = MFAStorage.D.enableEasterEggs
    @AppStorage(MFAStorage.K.scheduleType) var scheduleType: ScheduleType = MFAStorage.D.scheduleType
    @AppStorage(MFAStorage.K.showOnboarding) var showOnboarding: Bool = MFAStorage.D.showOnboarding
    @AppStorage(MFAStorage.K.visualizationMode) var visualizationMode: VisualizationMode = MFAStorage.D.visualizationMode
    @State private var scheduleEveryXDays: Int = 1
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @EnvironmentObject var secretsModel: SecretsViewModel

    var body: some View {
        VStack {
            NavigationView {
                List {
                    ScheduleControls(notificationsAllowed: $notificationsAllowed)
                        .environmentObject(notificationsModel)
                    SettingsControls(showOnboarding: $showOnboarding, enableEasterEggs: $enableEasterEggs, visualizationMode: $visualizationMode)
                    Section("About") {
                        NavigationLink(destination: AboutSheet()) {
                            Text("About MindFort")
                        }
                        NavigationLink(destination: Roadmap()) {
                            Text("Development Roadmap")
                        }
                    }
                    Section("Developer") {
                        NavigationLink(destination: DevControlPanel().environmentObject(secretsModel)) {
                            Text("Developer control panel")
                        }
                    }
                }
                .navigationBarTitle("Settings", displayMode: .inline)
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
        let secretsModelTwoSecrets = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleSecrets))
        let notificationsVmNoSchedules = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))

        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(notificationsVmNoSchedules)
                        .environmentObject(secretsModelTwoSecrets)
            }
            .previewDisplayName("Simple, no schedules")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(true))
                        .environmentObject(notificationsVmNoSchedules)
                        .environmentObject(secretsModelTwoSecrets)
                }
                .previewDisplayName("Simple, one schedule")
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    SettingsSheet(notificationsAllowed: .constant(false))
                        .environmentObject(notificationsVmNoSchedules)
                        .environmentObject(secretsModelTwoSecrets)
                }
                .previewDisplayName("Notifications not allowed")
        }
    }
}
