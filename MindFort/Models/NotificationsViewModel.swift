//
//  NotificationsViewModel.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-31.
//

import Foundation
import UserNotifications
import Combine


struct NotificationsVmData {
    var scheduleType: ScheduleType
}


protocol NotificationsVmDataLoader {
    func loadRegularIntervals() -> [DateComponents]
    func saveRegularIntervals(schedules: [DateComponents]) -> ()
    func deleteAllData() -> ()
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
            appLogger.info("When loading, found intervals: \(schedules)")
            return schedules
        } catch {
            appLogger.error("Error loading items: \(error)")
            return []
        }
    }

    func saveRegularIntervals(schedules: [DateComponents]) {
        do {
            let data = try encoder.encode(schedules)
            appLogger.info("Writing data to \(self.plistURL):\n\(data)")
            try data.write(to: plistURL)
        } catch {
            appLogger.error("Error saving items: \(error)")
        }
    }
    
    func deleteAllData() {
        do {
            try FileManager.default.removeItem(at: plistURL)
        } catch {
            appLogger.error("Error deleting \(self.plistURL): \(error)")
        }
    }
}

/// "Load" notification data from code literals that could be passed in from a preview function
class NotificationsVmDataLoaderFromArray: NotificationsVmDataLoader {
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
    func deleteAllData() {
        schedules = []
    }
}


enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case daily
//    case weekly
//    case monthly
//    case spacedRepetition
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .daily: return "Every day"
//        case .spacedRepetition: return "Spaced repetition"
        }
    }
}


func notificationIdentifierFromDateComponents(_ components: DateComponents, prefix: String = "") -> String {
    return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)-\(components.second ?? 0)"
}


class NotificationsViewModel: ObservableObject {
    @Published var scheduleType: ScheduleType = .daily
    @Published var regularIntervalEntries: [DateComponents] = [] {
        didSet {
            if oldValue != regularIntervalEntries {
                appLogger.debug("NotificationsViewModel regularIntervalEntries .didSet: value changed, updating...")
                save()
                reregisterNotifications()
            } else {
                appLogger.debug("NotificationsViewModel regularIntervalEntries .didSet: value didn't change, nothing to do")
            }
        }
    }
    private var cancellables = Set<AnyCancellable>()
    
    //    @Published var spacedRepetitionIntervalEntries
            
    private var dataLoader: NotificationsVmDataLoader
    private var manager: NotificationManager = NotificationManager.shared

    init(dataLoader: NotificationsVmDataLoader) {
        self.dataLoader = dataLoader
        load()
        
        // Subscribe to changes to regularIntervalEntries.
        // We store these in the cancellables property, so they are valid for the lifetime of the NotificationsViewModel.
        // ([weak self] prevents a memory leak with automatic reference counting)
        $regularIntervalEntries
            .sink { [weak self] _ in
                self?.save()
                self?.reregisterNotifications()
            }
            .store(in: &cancellables)    }
    
    func save() {
        dataLoader.saveRegularIntervals(schedules: self.regularIntervalEntries)
    }
    
    func load() {
        regularIntervalEntries = dataLoader.loadRegularIntervals()
    }
    
    func addRegularIntervalEntry(_ entry: DateComponents) {
        // Don't allow inserting the same interval twice
        if regularIntervalEntries.firstIndex(of: entry) != nil {
            return
        }
        regularIntervalEntries.append(entry)
    }
    
    func deleteRegularIntervalEntry(at offsets: IndexSet) {
        for index in offsets {
            regularIntervalEntries.remove(at: index)
        }
    }
    
    func deleteRegularIntervalEntry(_ entry: DateComponents) {
        if let index = regularIntervalEntries.firstIndex(of: entry) {
            deleteRegularIntervalEntry(at: IndexSet(integer: index))
        }
    }
    
    func reregisterNotifications() {
        // Don't do anything if the user hasn't granted us notification permissions
        NotificationManager.shared.requestPermission { granted in
            if granted {
                self.manager.removeNotifications()
                for schedule in self.regularIntervalEntries {
                    let trigger = UNCalendarNotificationTrigger(dateMatching: schedule, repeats: true)
                    let identifier = notificationIdentifierFromDateComponents(schedule, prefix: "RegularIntervals-")
                    self.manager.registerNotification(
                        title: "Password ritual",
                        body: "Time to perform a passphrase ritual 🙏",
                        identifier: identifier,
                        trigger: trigger
                    )
                }
            }
        }
    }
    
    func deleteAllData() {
        manager.removeNotifications()
        dataLoader.deleteAllData()
    }
}
