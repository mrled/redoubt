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
            minimumSlotBuffer: 6 * 60 * 60,
            slotLabels: ["Morning"]
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
            minimumSlotBuffer: 6 * 60 * 60,
            slotLabels: ["Daily"]
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

    // Test Case: Default schedule has two slots
    func testDefaultScheduleHasTwoSlots() throws {
        let defaultSchedule = ExpandingIntervalSchedule.default

        XCTAssertEqual(defaultSchedule.defaultSlots.count, 2, "Default schedule should have 2 notification slots")
        XCTAssertEqual(defaultSchedule.slotLabels.count, 2, "Default schedule should have 2 slot labels")
        XCTAssertEqual(defaultSchedule.slotLabels[0], "Morning", "First slot should be 'Morning'")
        XCTAssertEqual(defaultSchedule.slotLabels[1], "Evening", "Second slot should be 'Evening'")
    }

    // Test Case: Once daily schedule has one slot
    func testOnceDailyScheduleHasOneSlot() throws {
        let onceDailySchedule = ExpandingIntervalSchedule.onceDaily

        XCTAssertEqual(onceDailySchedule.defaultSlots.count, 1, "Once daily schedule should have 1 notification slot")
        XCTAssertEqual(onceDailySchedule.slotLabels.count, 1, "Once daily schedule should have 1 slot label")
        XCTAssertEqual(onceDailySchedule.slotLabels[0], "Daily", "Slot should be labeled 'Daily'")
        XCTAssertEqual(onceDailySchedule.minimumSlotBuffer, 0, "Once daily schedule should have no minimum buffer")
    }

    // Test Case: Both predefined schedules use same intervals
    func testPredefinedSchedulesUseSameIntervals() throws {
        let defaultSchedule = ExpandingIntervalSchedule.default
        let onceDailySchedule = ExpandingIntervalSchedule.onceDaily

        XCTAssertEqual(defaultSchedule.intervals, onceDailySchedule.intervals, "Both schedules should use the same Fibonacci-like intervals")
    }

    // Test Case: Slot labels work correctly
    func testSlotLabels() throws {
        let schedule = ExpandingIntervalSchedule.onceDaily

        XCTAssertEqual(schedule.labelForSlot(at: 0), "Daily", "First slot should have correct label")
        XCTAssertEqual(schedule.labelForSlot(at: 1), "Slot 2", "Out of bounds slot should return generic label")
    }

    // Test Case: requiresSlotSpacing is true for multi-slot schedules with buffer
    func testDefaultScheduleRequiresSlotSpacing() throws {
        let defaultSchedule = ExpandingIntervalSchedule.default

        XCTAssertTrue(defaultSchedule.requiresSlotSpacing, "Default schedule with 2 slots and 6-hour buffer should require spacing")
    }

    // Test Case: requiresSlotSpacing is false for single-slot schedules
    func testOnceDailyScheduleDoesNotRequireSlotSpacing() throws {
        let onceDailySchedule = ExpandingIntervalSchedule.onceDaily

        XCTAssertFalse(onceDailySchedule.requiresSlotSpacing, "Once daily schedule with 1 slot should not require spacing")
    }

    // Test Case: ReviewSchedule enum exposes requiresSlotSpacing
    func testReviewScheduleExposesSlotSpacingRequirement() throws {
        let twiceDaily = ReviewSchedule.expanding(.default)
        let onceDaily = ReviewSchedule.expanding(.onceDaily)

        XCTAssertTrue(twiceDaily.requiresSlotSpacing, "Twice daily schedule should require spacing")
        XCTAssertFalse(onceDaily.requiresSlotSpacing, "Once daily schedule should not require spacing")
    }
}
