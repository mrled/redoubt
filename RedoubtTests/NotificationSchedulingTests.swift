import XCTest
@testable import Redoubt

final class NotificationSchedulingTests: XCTestCase {

    var calendar: Calendar!
    var slots: [DateComponents]!
    let sixHours: TimeInterval = 6 * 60 * 60

    override func setUpWithError() throws {
        calendar = Calendar.current
        // Default slots: 9am and 6pm
        slots = [
            DateComponents(hour: 9, minute: 0),
            DateComponents(hour: 18, minute: 0)
        ]
    }

    override func tearDownWithError() throws {
        calendar = nil
        slots = nil
    }

    // Helper to create a date at a specific time today
    func dateAt(hour: Int, minute: Int = 0, daysOffset: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        let baseDate = calendar.date(from: components)!

        if daysOffset != 0 {
            return calendar.date(byAdding: .day, value: daysOffset, to: baseDate)!
        }
        return baseDate
    }

    // Test Case: Due in past, before first slot, no previous notification
    // now = 7am, dueDate = yesterday, slots = [9am, 6pm], buffer = 6h, lastNotification = nil
    // Expected: 9am today
    func testDueInPastBeforeFirstSlot() throws {
        let now = dateAt(hour: 7)
        let dueDate = dateAt(hour: 12, daysOffset: -1) // Yesterday at noon
        let expected = dateAt(hour: 9) // 9am today

        let result = nextNotificationTime(dueDate: dueDate, slots: slots, buffer: sixHours, lastNotificationTime: nil, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for 9am today (within 1 minute)")
    }

    // Test Case: Due in past, between slots, no previous notification
    // now = 2pm, dueDate = yesterday, slots = [9am, 6pm], buffer = 6h, lastNotification = nil
    // Expected: 6pm today
    func testDueInPastBetweenSlots() throws {
        let now = dateAt(hour: 14) // 2pm
        let dueDate = dateAt(hour: 12, daysOffset: -1) // Yesterday at noon
        let expected = dateAt(hour: 18) // 6pm today

        let result = nextNotificationTime(dueDate: dueDate, slots: slots, buffer: sixHours, lastNotificationTime: nil, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for 6pm today (within 1 minute)")
    }

    // Test Case: Due in past, after last slot, no previous notification
    // now = 10pm, dueDate = yesterday, slots = [9am, 6pm], buffer = 6h, lastNotification = nil
    // Expected: 9am tomorrow
    func testDueInPastAfterLastSlot() throws {
        let now = dateAt(hour: 22) // 10pm
        let dueDate = dateAt(hour: 12, daysOffset: -1) // Yesterday at noon
        let expected = dateAt(hour: 9, daysOffset: 1) // 9am tomorrow

        let result = nextNotificationTime(dueDate: dueDate, slots: slots, buffer: sixHours, lastNotificationTime: nil, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for 9am tomorrow (within 1 minute)")
    }

    // Test Case: Due in future, no previous notification
    // now = 7am today, dueDate = tomorrow 8am, slots = [9am, 6pm], buffer = 6h, lastNotification = nil
    // Expected: 9am tomorrow
    func testDueInFuture() throws {
        let now = dateAt(hour: 7)
        let dueDate = dateAt(hour: 8, daysOffset: 1) // Tomorrow at 8am
        let expected = dateAt(hour: 9, daysOffset: 1) // 9am tomorrow

        let result = nextNotificationTime(dueDate: dueDate, slots: slots, buffer: sixHours, lastNotificationTime: nil, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for 9am tomorrow (within 1 minute)")
    }

    // Test Case: Buffer enforcement from last notification
    // Scenario: Notified at 9am, user opens app at 2pm (5 hours later)
    // lastNotification = 9am, now = 2pm, dueDate = yesterday, slots = [9am, 6pm], buffer = 6h
    // Expected: 6pm today (9 hours after last notification, satisfies 6hr buffer)
    func testBufferEnforcement() throws {
        let lastNotification = dateAt(hour: 9) // Notified at 9am today
        let now = dateAt(hour: 14) // User opens app at 2pm
        let dueDate = dateAt(hour: 12, daysOffset: -1) // Yesterday at noon
        let expected = dateAt(hour: 18) // 6pm today

        let result = nextNotificationTime(dueDate: dueDate, slots: slots, buffer: sixHours, lastNotificationTime: lastNotification, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for 6pm today (9 hours after 9am notification)")
    }

    // Test Case: Empty slots
    // now = 9am, dueDate = yesterday, slots = [], buffer = 6h, lastNotification = nil
    // Expected: nil
    func testEmptySlots() throws {
        let now = dateAt(hour: 9)
        let dueDate = dateAt(hour: 12, daysOffset: -1)
        let emptySlots: [DateComponents] = []

        let result = nextNotificationTime(dueDate: dueDate, slots: emptySlots, buffer: sixHours, lastNotificationTime: nil, now: now)

        XCTAssertNil(result, "Should return nil when no slots are provided")
    }

    // Test Case: Buffer prevents closely-spaced re-notifications
    // Scenario: Notified at 9am, if we sent another at 10am it would violate 6hr buffer
    // slots = [9am, 10am], lastNotification = 9am, now = 9:05am, buffer = 6h
    // Expected: Skip 10am, must wait until 9am + 6hr = 3pm or later
    func testCloseSlotsPrevented() throws {
        let closeSlots = [
            DateComponents(hour: 9, minute: 0),
            DateComponents(hour: 10, minute: 0),
            DateComponents(hour: 15, minute: 0) // 3pm
        ]

        let lastNotification = dateAt(hour: 9) // Notified at 9am
        let now = dateAt(hour: 9, minute: 5) // App reopened at 9:05am
        let dueDate = dateAt(hour: 12, daysOffset: -1) // Yesterday
        let expected = dateAt(hour: 15) // 3pm (6 hours after 9am)

        let result = nextNotificationTime(dueDate: dueDate, slots: closeSlots, buffer: sixHours, lastNotificationTime: lastNotification, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should skip 10am and schedule for 3pm (6 hours after last notification)")
    }

    // Test Case: Notification time must be in the future
    // If now = 9:05am and 9am slot has passed, must use next available slot
    // No previous notification, so buffer doesn't apply
    func testMustBeInFuture() throws {
        let now = dateAt(hour: 9, minute: 5) // 9:05am (just after 9am slot)
        let dueDate = dateAt(hour: 12, daysOffset: -1) // Yesterday
        let expected = dateAt(hour: 18) // 6pm today (next slot in future)

        let result = nextNotificationTime(dueDate: dueDate, slots: slots, buffer: sixHours, lastNotificationTime: nil, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for 6pm (next slot in future)")
    }

    // Test Case: Buffer from last notification can push to next day
    // Scenario: Notified at noon, user opens app at 1pm
    // lastNotification = noon, now = 1pm, next valid slot is 9am tomorrow (noon + 6hr = 6pm, already passed)
    func testBufferPushesToNextDay() throws {
        let lastNotification = dateAt(hour: 12) // Notified at noon
        let now = dateAt(hour: 13) // 1pm - user opens app 1 hour later
        let dueDate = dateAt(hour: 8, daysOffset: -1) // Yesterday 8am

        // Buffer from noon = 6pm (12 + 6 hours)
        // But now it's already 1pm, so 6pm slot is still available
        let expected = dateAt(hour: 18) // 6pm today

        let result = nextNotificationTime(dueDate: dueDate, slots: slots, buffer: sixHours, lastNotificationTime: lastNotification, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for 6pm today (6 hours after noon)")
    }

    // Test Case: Single slot scenario, no previous notification
    func testSingleSlot() throws {
        let singleSlot = [DateComponents(hour: 9, minute: 0)]
        let now = dateAt(hour: 7)
        let dueDate = dateAt(hour: 12, daysOffset: -1)
        let expected = dateAt(hour: 9)

        let result = nextNotificationTime(dueDate: dueDate, slots: singleSlot, buffer: sixHours, lastNotificationTime: nil, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for the single available slot (within 1 minute)")
    }

    // Test Case: Multiple slots throughout the day, with last notification
    // Scenario: Notified at 6am, user opens app at 8am
    // Should pick noon (6 hours after 6am notification)
    func testMultipleSlotsThroughoutDay() throws {
        let multipleSlots = [
            DateComponents(hour: 6, minute: 0),  // 6am
            DateComponents(hour: 12, minute: 0), // noon
            DateComponents(hour: 18, minute: 0)  // 6pm
        ]

        let lastNotification = dateAt(hour: 6) // Notified at 6am
        let now = dateAt(hour: 8) // 8am
        let dueDate = dateAt(hour: 12, daysOffset: -1)

        // 6am + 6h buffer = noon (earliest allowed)
        let expected = dateAt(hour: 12) // noon today

        let result = nextNotificationTime(dueDate: dueDate, slots: multipleSlots, buffer: sixHours, lastNotificationTime: lastNotification, now: now)

        XCTAssertNotNil(result, "Should return a notification time")

        let timeDifference = abs(result!.timeIntervalSince(expected))
        XCTAssertLessThan(timeDifference, 60.0, "Should schedule for noon (6 hours after 6am notification)")
    }
}
