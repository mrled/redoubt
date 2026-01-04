import Foundation

/// A review schedule defines when secrets should be reviewed.
/// Currently supports expanding interval schedules, with room for future schedule types.
enum ReviewSchedule: Codable, Identifiable {
    case expanding(ExpandingIntervalSchedule)
    // Future: case custom(CustomSchedule)

    var id: UUID {
        switch self {
        case .expanding(let schedule): return schedule.id
        }
    }

    var name: String {
        switch self {
        case .expanding(let schedule): return schedule.name
        }
    }

    /// Calculate the next review date for a secret based on its history
    /// - Parameters:
    ///   - lastQuizzed: The last time the secret was quizzed (nil if never quizzed)
    ///   - consecutiveSuccesses: Number of consecutive successful quizzes
    /// - Returns: The date when the secret should be reviewed next, or nil if no review needed
    func nextReviewDate(lastQuizzed: Date?, consecutiveSuccesses: Int) -> Date? {
        switch self {
        case .expanding(let schedule):
            return schedule.nextReviewDate(lastQuizzed: lastQuizzed, consecutiveSuccesses: consecutiveSuccesses)
        }
    }
}

/// An expanding interval schedule with predefined intervals that grow over time.
/// Uses Fibonacci-like intervals for spaced repetition.
struct ExpandingIntervalSchedule: Codable {
    let id: UUID
    var name: String
    let intervals: [Int]  // days, e.g. [1, 2, 3, 5, 8, 13, 21, 34]

    // Notification configuration (schedule provides defaults, user can customize)
    let defaultSlots: [DateComponents]    // e.g., [9am, 6pm]
    let minimumSlotBuffer: TimeInterval   // e.g., 6 hours (21600 seconds)

    /// Calculate the next review date based on quiz history
    /// - Parameters:
    ///   - lastQuizzed: The last time the secret was quizzed (nil if never quizzed)
    ///   - consecutiveSuccesses: Number of consecutive successful quizzes
    /// - Returns: The date when the secret should be reviewed next
    func nextReviewDate(lastQuizzed: Date?, consecutiveSuccesses: Int) -> Date? {
        // If never quizzed, review immediately
        guard let last = lastQuizzed else { return Date() }

        // Get the interval based on consecutive successes, clamped to the last interval
        let index = min(consecutiveSuccesses, intervals.count - 1)
        let daysToAdd = intervals[index]

        // Calculate next review date
        return Calendar.current.date(byAdding: .day, value: daysToAdd, to: last)
    }

    /// Default expanding interval schedule with Fibonacci-like intervals
    static let `default` = ExpandingIntervalSchedule(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Expanding Intervals",
        intervals: [1, 2, 3, 5, 8, 13, 21, 34],
        defaultSlots: [
            DateComponents(hour: 9, minute: 0),   // 9:00 AM
            DateComponents(hour: 18, minute: 0)   // 6:00 PM
        ],
        minimumSlotBuffer: 6 * 60 * 60  // 6 hours in seconds
    )
}
