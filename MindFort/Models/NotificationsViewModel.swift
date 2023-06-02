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
    func loadOneTimes() -> [DateComponents]
    func saveOneTimes(components: [DateComponents]) -> ()
    func deleteAllData() -> ()
}


/// Load secret data from a property list in the app's documents directory
class NotificationsVmDataLoaderFromPlist: NotificationsVmDataLoader {
    
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()

    init() {}

    private var plistUrlRegularIntervals: URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }
        return documentsURL.appendingPathComponent("RegularIntervalNotifications.plist")
    }
    private var plistUrlOneTimes: URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory.")
        }
        return documentsURL.appendingPathComponent("OneTimeNotifications.plist")
    }
    
    private func loadPlist<T: Decodable>(plistUrl: URL) -> [T] {
        do {
            let rawData = try Data(contentsOf: plistUrl)
            let result = try decoder.decode([T].self, from: rawData)
            appLogger.info("When loading from plist \(plistUrl), found data: \(result)")
            return result
        } catch {
            appLogger.error("Error loading from plist \(plistUrl): \(error)")
            return []
        }
    }
    
    private func savePlist<T: Encodable>(plistUrl: URL, data: [T]) {
        do {
            let encodedData = try encoder.encode(data)
            appLogger.info("Writing data to \(plistUrl):\n\(encodedData)")
            try encodedData.write(to: plistUrl)
        } catch {
            appLogger.error("Error saving data to \(plistUrl): \(error)")
        }

    }

    func loadRegularIntervals() -> [DateComponents] {
        return loadPlist(plistUrl: plistUrlRegularIntervals)
    }

    func saveRegularIntervals(schedules: [DateComponents]) {
        savePlist(plistUrl: plistUrlRegularIntervals, data: schedules)
    }
    
    func loadOneTimes() -> [DateComponents] {
        return loadPlist(plistUrl: plistUrlOneTimes)
    }
    
    func saveOneTimes(components: [DateComponents]) {
        savePlist(plistUrl: plistUrlOneTimes, data: components)
    }
    
    func deleteAllData() {
        do {
            try FileManager.default.removeItem(at: plistUrlRegularIntervals)
            try FileManager.default.removeItem(at: plistUrlOneTimes)
        } catch {
            appLogger.error("Error deleting \(self.plistUrlRegularIntervals): \(error)")
        }
    }
}

/// "Load" notification data from code literals that could be passed in from a preview function
class NotificationsVmDataLoaderFromArray: NotificationsVmDataLoader {
    var schedules: [DateComponents]
    var oneTimes: [DateComponents]
    
    init(schedules: [DateComponents], oneTimes: [DateComponents]) {
        self.schedules = schedules
        self.oneTimes = oneTimes
    }
    
    func loadRegularIntervals() -> [DateComponents] {
        return schedules
    }
    func saveRegularIntervals(schedules schedulesIn: [DateComponents]) {
        schedules = schedulesIn
    }
    func loadOneTimes() -> [DateComponents] {
        return oneTimes
    }
    func saveOneTimes(components: [DateComponents]) {
        oneTimes = components
    }

    func deleteAllData() {
        schedules = []
        oneTimes = []
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


func addQuizNotification(components: DateComponents, prefix: String, repeats: Bool) {
    print("Going to add a quiz notification...")
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    let identifier = notificationIdentifierFromDateComponents(components, prefix: prefix)
    
    let content = UNMutableNotificationContent()
    content.title = "Type the magic words"
    content.body = "Time to perform a passphrase ritual 🙏"
    content.userInfo = ["action": "startQuiz"]
    
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { (error) in
        if let error {
            appLogger.error("Error adding notification request with id \(identifier): \(error)")
        } else {
            appLogger.debug("Successfully registered quiz notification with id \(identifier)")
        }
    }
}


class NotificationsViewModel: ObservableObject {
    @Published var scheduleType: ScheduleType = .daily
    
    // These didSet closures handle persisting the change to the plists when we change the entries
    @Published var regularIntervalEntries: [DateComponents] = [] {
        didSet {
            if oldValue != regularIntervalEntries {
                appLogger.debug("NotificationsViewModel regularIntervalEntries .didSet: value changed, persisting...")
//                save()
//                reregisterNotifications()
                dataLoader.saveRegularIntervals(schedules: self.regularIntervalEntries)
            } else {
                appLogger.debug("NotificationsViewModel regularIntervalEntries .didSet: value didn't change, nothing to do")
            }
        }
    }
    @Published var oneTimeEntries: [DateComponents] = [] {
        didSet {
            if oldValue != oneTimeEntries {
                appLogger.debug("NotificationsViewModel oneTimeEntries .didSet: value changed, persisting...")
//                save()
//                reregisterNotifications()
                dataLoader.saveOneTimes(components: self.oneTimeEntries)
            } else {
                appLogger.debug("NotificationsViewModel oneTimeEntries .didSet: value didn't change, nothing to do")
            }
        }
    }
    
    private var regularIntervalsEntriesCancellables = Set<AnyCancellable>()
    private var oneTimeEntriesCancellables = Set<AnyCancellable>()

    private var dataLoader: NotificationsVmDataLoader
    private var manager: NotificationManager = NotificationManager.shared

    init(dataLoader: NotificationsVmDataLoader) {
        self.dataLoader = dataLoader
        load()
        
        // These subscritions handle making the change in the Notification Center when we change entries
        // We store these in the cancellables property, so they are valid for the lifetime of the NotificationsViewModel.
        // ([weak self] prevents a memory leak with automatic reference counting)
        $regularIntervalEntries
            .sink { [weak self] _ in
                appLogger.debug("NotificationsViewModel $regularIntervalEntries .sink: noticed change, reregistering...")
//                self?.save()
                self?.reregisterNotifications()
            }
            .store(in: &regularIntervalsEntriesCancellables)
        $oneTimeEntries
            .sink { [weak self] _ in
                appLogger.debug("NotificationsViewModel $oneTimeEntries .sink: noticed change, reregistering...")
//                self?.save()
                self?.reregisterNotifications()
            }
            .store(in: &oneTimeEntriesCancellables)
    }
    
    func save() {
        dataLoader.saveRegularIntervals(schedules: self.regularIntervalEntries)
        dataLoader.saveOneTimes(components: self.oneTimeEntries)
    }
    
    func load() {
        regularIntervalEntries = dataLoader.loadRegularIntervals()
        oneTimeEntries = dataLoader.loadOneTimes()
    }
    
    // TODO: now that I'm observing regularIntervalEntries / oneTimeEntries with the .sink, can I get rid of these add/delete helpers?
    
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
    
//    func addOneTimeEntry(_ components: DateComponents) {
//        // Don't allow inserting the same interval twice
//        if oneTimeEntries.firstIndex(of: components) != nil {
//            return
//        }
//        oneTimeEntries.append(components)
//    }
//    
//    func deleteOneTimeEntry(at offsets: IndexSet) {
//        for index in offsets {
//            oneTimeEntries.remove(at: index)
//        }
//    }
//    func deleteOneTimeEntry(_ components: DateComponents) {
//        if let index = oneTimeEntries.firstIndex(of: components) {
//            deleteOneTimeEntry(at: IndexSet(integer: index))
//        }
//    }

    func reregisterNotifications() {
        // Don't do anything if the user hasn't granted us notification permissions
        NotificationManager.shared.requestPermission { granted in
            if granted {
                appLogger.debug("reregisterNotifications: granted permission to notify, registering...")
                self.manager.removeNotifications()
                
                for schedule in self.regularIntervalEntries {
                    addQuizNotification(components: schedule, prefix: "RegularIntervals-", repeats: true)
                }
                
                for components in self.oneTimeEntries {
                    addQuizNotification(components: components, prefix: "OneTime-", repeats: false)
                }
            } else {
                appLogger.debug("reregisterNotifications: not granted permission to notify, nothing we can do")
            }
        }
    }
    
    func deleteAllData() {
        regularIntervalEntries = []
        oneTimeEntries = []
        manager.removeNotifications()
        dataLoader.deleteAllData()
    }
}
