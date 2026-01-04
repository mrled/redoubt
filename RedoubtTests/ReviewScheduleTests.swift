import XCTest
@testable import Redoubt

final class ReviewScheduleTests: XCTestCase {

    var schedule: ExpandingIntervalSchedule!
    var calendar: Calendar!

    override func setUpWithError() throws {
        calendar = Calendar.current
        schedule = ExpandingIntervalSchedule(
            id: UUID(),
            name: "Test Schedule",
            intervals: [1, 2, 3, 5, 8],
            defaultSlots: [DateComponents(hour: 9, minute: 0)],
            minimumSlotBuffer: 6 * 60 * 60
        )
    }

    override func tearDownWithError() throws {
        schedule = nil
        calendar = nil
    }

    // Test Case: Never quizzed - should return now
    func testNeverQuizzed() throws {
        let result = schedule.nextReviewDate(lastQuizzed: nil, consecutiveSuccesses: 0)

        XCTAssertNotNil(result, "Should return a date for never-quizzed secret")

        // Result should be approximately now (within 1 second)
        let now = Date()
        let timeDifference = abs(result!.timeIntervalSince(now))
        XCTAssertLessThan(timeDifference, 1.0, "Should return current date for never-quizzed secret")
    }

    // Test Case: After first success - should be +1 day
    func testAfterFirstSuccess() throws {
        let today = Date()
        let result = schedule.nextReviewDate(lastQuizzed: today, consecutiveSuccesses: 0)

        XCTAssertNotNil(result, "Should return a date")

        let expectedDate = calendar.date(byAdding: .day, value: 1, to: today)!
        let timeDifference = abs(result!.timeIntervalSince(expectedDate))

        // Should be within a few seconds (accounting for any clock drift during test)
        XCTAssertLessThan(timeDifference, 5.0, "Should be 1 day after last quizzed")
    }

    // Test Case: After 3 successes - should use 4th interval (index 3)
    func testAfterThreeSuccesses() throws {
        let today = Date()
        let result = schedule.nextReviewDate(lastQuizzed: today, consecutiveSuccesses: 3)

        XCTAssertNotNil(result, "Should return a date")

        // intervals[3] = 5 days
        let expectedDate = calendar.date(byAdding: .day, value: 5, to: today)!
        let timeDifference = abs(result!.timeIntervalSince(expectedDate))

        XCTAssertLessThan(timeDifference, 5.0, "Should be 5 days after last quizzed")
    }

    // Test Case: Beyond interval count - should clamp to last interval
    func testBeyondIntervalCount() throws {
        let today = Date()

        // consecutiveSuccesses = 10, but intervals only has 5 elements (indices 0-4)
        let result = schedule.nextReviewDate(lastQuizzed: today, consecutiveSuccesses: 10)

        XCTAssertNotNil(result, "Should return a date")

        // Should use last interval: intervals[4] = 8 days
        let expectedDate = calendar.date(byAdding: .day, value: 8, to: today)!
        let timeDifference = abs(result!.timeIntervalSince(expectedDate))

        XCTAssertLessThan(timeDifference, 5.0, "Should use last interval (8 days) when beyond interval count")
    }

    // Test Case: Verify each interval index maps correctly
    func testIntervalMapping() throws {
        let today = Date()
        let expectedIntervals = [1, 2, 3, 5, 8]

        for (index, expectedDays) in expectedIntervals.enumerated() {
            let result = schedule.nextReviewDate(lastQuizzed: today, consecutiveSuccesses: index)
            XCTAssertNotNil(result, "Should return a date for consecutiveSuccesses=\(index)")

            let expectedDate = calendar.date(byAdding: .day, value: expectedDays, to: today)!
            let timeDifference = abs(result!.timeIntervalSince(expectedDate))

            XCTAssertLessThan(
                timeDifference,
                5.0,
                "For \(index) consecutive successes, should add \(expectedDays) days"
            )
        }
    }

    // Test Case: ReviewSchedule enum wrapper
    func testReviewScheduleEnumWrapper() throws {
        let expandingSchedule = ExpandingIntervalSchedule(
            id: UUID(),
            name: "Test Enum Schedule",
            intervals: [1, 2, 3],
            defaultSlots: [DateComponents(hour: 9, minute: 0)],
            minimumSlotBuffer: 6 * 60 * 60
        )

        let reviewSchedule = ReviewSchedule.expanding(expandingSchedule)

        XCTAssertEqual(reviewSchedule.id, expandingSchedule.id, "ID should match")
        XCTAssertEqual(reviewSchedule.name, expandingSchedule.name, "Name should match")

        let today = Date()
        let result = reviewSchedule.nextReviewDate(lastQuizzed: today, consecutiveSuccesses: 1)

        XCTAssertNotNil(result, "Should return a date through enum wrapper")

        let expectedDate = calendar.date(byAdding: .day, value: 2, to: today)!
        let timeDifference = abs(result!.timeIntervalSince(expectedDate))

        XCTAssertLessThan(timeDifference, 5.0, "Should calculate correctly through enum wrapper")
    }
}
