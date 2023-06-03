//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI
import Foundation


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
    @AppStorage("scheduleEnabled") var scheduleEnabled: Bool = true
    @AppStorage("scheduleType") var scheduleType: ScheduleType = .daily

    var body: some View {
        Section("Schedule") {
            Toggle(isOn: $scheduleEnabled) {
                Text("Enable scheduled reminders")
            }
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
            .disabled(!scheduleEnabled)
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


struct NotificationsControls: View {
    @Binding var notificationsAllowed: Bool
    var body: some View {
        Section("Notifications") {
            if notificationsAllowed {
                Text("Notifications are allowed")
            } else {
                Text("To get the most out of MindFort, please enable notifications in Settings.")
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        RowItemUrlWithIcon(title: "Open Settings", systemImageName: "gear", destination: url)
                    }
                }
            }
        }
    }
}


struct DeveloperControls: View {
    @Binding var showControlPanel: Bool
    @Binding var enableEasterEggs: Bool
    var body: some View {
        Section("Developers") {
            Toggle(isOn: $showControlPanel) {
                Text("Show secret developer control panels")
            }
            Toggle(isOn: $enableEasterEggs) {
                Text("Enable easter eggs")
            }
        }
    }
}

struct SettingsSheet: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @AppStorage("showControlPanel") var showControlPanel: Bool = false
    @AppStorage("enableEasterEggs") var enableEasterEggs: Bool = false
    @AppStorage("scheduleType") var scheduleType: ScheduleType = .daily
    @State private var notificationsAllowed: Bool = false
    @State private var scheduleEveryXDays: Int = 1

    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .bold()
                .padding()
            List {
                ScheduleControls()
                    .environmentObject(notificationsModel)
                NotificationsControls(notificationsAllowed: $notificationsAllowed)
                DeveloperControls(showControlPanel: $showControlPanel, enableEasterEggs: $enableEasterEggs)
            }
        }
        .onAppear {
            NotificationManager.shared.requestPermission { granted in
                notificationsAllowed = granted
            }
        }
    
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
                SettingsSheet()
                    .environmentObject(notificationsViewModel)
            }
            .previewDisplayName("Simple, no schedules")
        }
        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
                    SettingsSheet()
                        .environmentObject(notificationsViewModel)
                }
                .previewDisplayName("Simple, one schedule")
        }
    }
}
