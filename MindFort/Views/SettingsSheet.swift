//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI
import Foundation


/// Kind of a weird implementation
/// - We need a scheduleTime @Binding because of the caller
/// - We compute a date property from that to use internally
/// - We need a @State datePickerDate property to stay updated to the date/scheduleTime
///     because it cannot bind to a computed property directly
struct ScheduleTimePicker: View {
    @Binding var scheduleTime: ScheduleTime
    @State var expanded: Bool = false
    @State private var datePickerDate: Date
    
    init(scheduleTime: Binding<ScheduleTime>) {
        self._scheduleTime = scheduleTime
        self._datePickerDate = State(initialValue: Calendar.current.date(from: scheduleTime.wrappedValue.dateComponents) ?? Date())
    }

    var body: some View {
        VStack {
            HStack {
                Text("At ")
                Button(action: {
                    expanded.toggle()
                }) {
                    Text(formatTime(date))
                        .foregroundColor(Color.blue)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            if expanded {
                VStack {
                    Text("Add a new time")
                        .padding()
                    DatePicker(selection: $datePickerDate, displayedComponents: .hourAndMinute) {
                        Text("")
                    }
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                }
                .onChange(of: datePickerDate) { newDate in
                    let newDateComponents = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                    scheduleTime = ScheduleTime(dateComponents: newDateComponents)
                }
            }
        }
    }
    
    var date: Date {
        get {
            Calendar.current.date(from: scheduleTime.dateComponents) ?? Date()
        }
        set {
            let newDateComponents = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            scheduleTime = ScheduleTime(dateComponents: newDateComponents)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct RegularIntervalScheduleControls: View {
    @Binding var scheduleEveryXDays: Int
    @Binding var scheduleTimes: [ScheduleTime]
    
    var body: some View {
        Group {
            DayWeekMonthIntervalPicker()
            if scheduleTimes.count > 0 {
                // WARNING: you cannot ForEach over a bound array and bind each element to a new child view!!!
                // If you do, Xcode will give you the most insane errors, and put them on the wrong line.
                // Instead you have to ForEach over indices, like this:
                ForEach(scheduleTimes.indices, id: \.self) { index in
                    ScheduleTimePicker(scheduleTime: $scheduleTimes[index])
                }
            } else {
                Text("No time set, will not send notification")
                    .foregroundColor(.gray)
            }
            Button("Add a time", action: addScheduleTime)
        }
    }
     
    func addScheduleTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let newScheduleTime = ScheduleTime(dateComponents: components)
        scheduleTimes.append(newScheduleTime)
    }
}


struct SpacedRepetitionScheduleControls: View {
    @AppStorage("spacedRepetitionIntervalDays") var spacedRepetitionIntervalDays: Int = 1
    @AppStorage("spacedRepetitionIntervalsPerDay") var spacedRepetitionIntervalsPerDay: Int = 1

    var body: some View {
        Group {
            Stepper(value: $spacedRepetitionIntervalDays, in: 1...7) {
                Text(spacedRepetitionIntervalText)
            }
            TimeRangePicker()
            // TODO: show the time the notification will be delivered
            // TODO: if $spacedRepetitionIntervalDays == 1, allow more than one time, and show an Add button at the bottom.
        }
    }
    
    var spacedRepetitionIntervalText: String {
        if spacedRepetitionIntervalDays > 1 {
            return "Every \(spacedRepetitionIntervalDays) days"
        } else if spacedRepetitionIntervalDays == 1 {
            return "Every \(spacedRepetitionIntervalDays) day"
        } else {
            if spacedRepetitionIntervalsPerDay == 0 {
                return "Never"
            } else if spacedRepetitionIntervalsPerDay == 1 {
                return "Once every day"
            } else if spacedRepetitionIntervalsPerDay == 2 {
                return "Twice every day"
            } else {
                return "\(spacedRepetitionIntervalsPerDay) times per day"
            }
        }
    }
}


struct ScheduleControls: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @AppStorage("scheduleEnabled") var scheduleEnabled: Bool = true
    @AppStorage("scheduleType") var scheduleType: ScheduleType = .regularInterval
    @Binding var scheduleEveryXDays: Int
    
    // with the .dateComponents property which comes from Day()
    // and for which we ONLY care about hours and minutes
    @Binding var scheduleTimes: [ScheduleTime]

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
                if scheduleType == .regularInterval {
                    RegularIntervalScheduleControls(
                        scheduleEveryXDays: $scheduleEveryXDays,
                        scheduleTimes: $scheduleTimes
                    )
                } else if scheduleType == .spacedRepetition {
                    SpacedRepetitionScheduleControls()
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
    var body: some View {
        Section("Developers") {
            Toggle(isOn: $showControlPanel) {
                Text("Show secret developer control panel")
            }
        }
    }
}

struct SettingsSheet: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @AppStorage("showControlPanel") var showControlPanel: Bool = false
    @AppStorage("scheduleType") var scheduleType: ScheduleType = .regularInterval
    @State private var notificationsAllowed: Bool = false
    @State private var scheduleEveryXDays: Int = 1
    @State private var scheduleTimes: [ScheduleTime] = []

    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .bold()
                .padding()
            List {
                ScheduleControls(
                    scheduleEveryXDays: $scheduleEveryXDays,
                    scheduleTimes: $scheduleTimes
                )
                .environmentObject(notificationsModel)
                NotificationsControls(notificationsAllowed: $notificationsAllowed)
                DeveloperControls(showControlPanel: $showControlPanel)
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
            let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromLiterals(schedules: []))
            SettingsSheet()
                .environmentObject(notificationsViewModel)
                .previewDisplayName("Simple, no schedules")
        }
        Group {
            let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromLiterals(schedules: []))
            SettingsSheet()
                .environmentObject(notificationsViewModel)
                .previewDisplayName("Simple, one schedule")
        }
    }
}
