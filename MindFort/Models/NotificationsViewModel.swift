//
//  NotificationsViewModel.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-31.
//

import Foundation
import UserNotifications


struct NotificationsVmData {
    var scheduleType: ScheduleType
}


protocol NotificationsVmDataLoader {
    func loadRegularIntervals() -> [DateComponents]
    func saveRegularIntervals(schedules: [DateComponents]) -> ()
}


/// Load secret data from a property list in the app's documents directory
class NotificationsVmDataLoaderFromPlist: NotificationsVmDataLoader {
    
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()

    init() {}

    private var plistURL: URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }
        return documentsURL.appendingPathComponent("RegularIntervalNotifications.plist")
    }

    func loadRegularIntervals() -> [DateComponents] {
        do {
            let data = try Data(contentsOf: plistURL)
            let schedules = try decoder.decode([DateComponents].self, from: data)
            print("When loading, found secrets: \(schedules)")
            return schedules
        } catch {
            // TODO: Handle errors here better
            print("Error loading items: \(error)")
            return []
        }
    }

    func saveRegularIntervals(schedules: [DateComponents]) {
        do {
            let data = try encoder.encode(schedules)
            try data.write(to: plistURL)
        } catch {
            print("Error saving items: \(error)")
        }
    }
}

/// "Load" notification data from code literals that could be passed in from a preview function
class NotificationsVmDataLoaderFromLiterals: NotificationsVmDataLoader {
    var schedules: [DateComponents]
    init(schedules: [DateComponents]) {
        self.schedules = schedules
    }
    func loadRegularIntervals() -> [DateComponents] {
        return schedules
    }
    func saveRegularIntervals(schedules schedulesIn: [DateComponents]) {
        schedules = schedulesIn
    }
}


enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case regularInterval
    case spacedRepetition
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .regularInterval: return "Regular interval"
        case .spacedRepetition: return "Spaced repetition"
        }
    }
}


/// A struct with DateComponents representing when notifications will be delivered
struct ScheduleTime: Identifiable {
    var dateComponents: DateComponents
    
    var id: String {
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        return "\(hour):\(minute)"
    }
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none // Ignore the date completely
        formatter.timeStyle = .short
        if let date = Calendar.current.date(from: dateComponents) {
            return formatter.string(from: date)
        } else {
            // TODO: should not return junk here
            return "Error: Bad Date"
        }
    }
}


class NotificationsViewModel: ObservableObject {
    @Published var scheduleType: ScheduleType = .regularInterval
    @Published var regularIntervalSchedules: [DateComponents] = []
    
    //    @Published var spacedRepetitionIntervalEntries
            
    private var dataLoader: NotificationsVmDataLoader
    private var manager: NotificationManager = NotificationManager.shared

    init(dataLoader: NotificationsVmDataLoader) {
        self.dataLoader = dataLoader
    }
    
    func save() {
        dataLoader.saveRegularIntervals(schedules: self.regularIntervalSchedules)
        reregisterNotifications()
    }
    
    func load() {
        regularIntervalSchedules = dataLoader.loadRegularIntervals()
        reregisterNotifications()
    }
    
    func addRegularIntervalEntry(_ entry: DateComponents) {
        // Don't allow inserting the same interval/time twice
        if regularIntervalSchedules.firstIndex(of: entry) != nil {
            return
        }
        regularIntervalSchedules.append(entry)
        save()
    }
    
    func deleteRegularIntervalEntry(_ entry: DateComponents) {
        if let index = regularIntervalSchedules.firstIndex(of: entry) {
            regularIntervalSchedules.remove(at: index)
            save()
        }
    }
    
    func reregisterNotifications() {
        // Don't do anything if the user hasn't granted us notification permissions
        NotificationManager.shared.requestPermission { granted in
            if granted {
                self.manager.removeNotifications()
                for schedule in self.regularIntervalSchedules {
                    let trigger = UNCalendarNotificationTrigger(dateMatching: schedule, repeats: true)
                    self.manager.registerNotification(
                        title: "Password ritual",
                        body: "Time to perform a passphrase ritual 🙏",
                        identifier: "RegularIntervals-\(schedule.description)",
                        trigger: trigger
                    )
                }
            }
        }
    }
}
