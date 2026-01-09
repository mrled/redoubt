import Foundation
import UserNotifications


func notificationIdentifierFromDateComponents(_ components: DateComponents, prefix: String = "") -> String {
    return "\(prefix)\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)-\(components.hour ?? 0)-\(components.minute ?? 0)-\(components.second ?? 0)"
}


func addQuizNotification(components: DateComponents, prefix: String, repeats: Bool) {
    print("Going to add a quiz notification...")
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
    let identifier = notificationIdentifierFromDateComponents(components, prefix: prefix)
    
    let content = UNMutableNotificationContent()
    content.title = "Type the magic words"
    content.body = "Time to perform a passphrase ritual 🙏"
    content.userInfo = [MFAStorage.K.notificationAction: "startQuiz"]
    
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { (error) in
        if let error {
            appLogger.error("Error adding notification request with id \(identifier): \(error)")
        } else {
            appLogger.debug("Successfully registered quiz notification with id \(identifier)")
        }
    }
}


/// Calculate the next notification time based on due date, notification slots, and buffer requirements
/// - Parameters:
///   - dueDate: The date when the secret is due for review
///   - slots: Array of time slots (e.g., 9am, 6pm) when notifications can be sent
///   - buffer: Minimum time interval between notifications (in seconds)
///   - lastNotificationTime: When the last notification was sent (nil if never sent)
///   - now: Current time (defaults to Date(), injectable for testing)
/// - Returns: The next appropriate notification time, or nil if no valid slot exists
func nextNotificationTime(dueDate: Date, slots: [DateComponents], buffer: TimeInterval, lastNotificationTime: Date? = nil, now: Date = Date()) -> Date? {
    // Find the earliest slot that is:
    // 1. On or after dueDate
    // 2. At least `buffer` from last notification (to prevent re-notification spam)
    // 3. In the future (>= now)

    guard !slots.isEmpty else { return nil }

    let calendar = Calendar.current

    // Calculate earliest allowed time based on buffer from last notification
    let bufferReference = lastNotificationTime ?? Date.distantPast
    let earliestFromBuffer = bufferReference.addingTimeInterval(buffer)
    let earliestAllowed = max(dueDate, earliestFromBuffer, now)

    // Generate candidate slot times for today and tomorrow (covers all cases)
    var candidates: [Date] = []
    for dayOffset in 0...1 {
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: earliestAllowed) else { continue }
        for slot in slots {
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = slot.hour
            components.minute = slot.minute
            components.second = 0
            if let candidate = calendar.date(from: components) {
                candidates.append(candidate)
            }
        }
    }

    // Return the earliest candidate that meets all criteria
    return candidates
        .filter { $0 >= earliestAllowed }
        .sorted()
        .first
}
