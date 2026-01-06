import SwiftUI
import Foundation

struct NotificationSlotsEditor: View {
    @Binding var slots: [DateComponents]
    let schedule: ReviewSchedule
    let onSlotsChanged: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notification Times")
                .font(.headline)

            ForEach(slots.indices, id: \.self) { index in
                HStack {
                    Text(schedule.labelForSlot(at: index))
                        .frame(width: 80, alignment: .leading)

                    if let range = allowedRange(for: index) {
                        DatePicker(
                            "",
                            selection: binding(for: index),
                            in: range,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    } else {
                        DatePicker(
                            "",
                            selection: binding(for: index),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }
            }

            if schedule.requiresSlotSpacing {
                Text("Times must be at least \(schedule.formattedMinimumBuffer()) apart")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    private func allowedRange(for index: Int) -> ClosedRange<Date>? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let buffer = schedule.minimumSlotBuffer

        // For single-slot schedules, no constraint needed
        if slots.count == 1 {
            return nil
        }

        // For the first slot, constrain based on what comes after
        if index == 0, slots.count > 1 {
            // Morning must leave enough time for Evening (and wrap-around)
            let nextSlotTime = calendar.date(from: slots[index + 1]) ?? today
            let maxTime = calendar.date(byAdding: .second, value: -Int(buffer), to: nextSlotTime) ?? today

            // Ensure valid range (maxTime must be >= today)
            guard maxTime >= today else { return nil }

            // Allow from start of day to (nextSlot - buffer)
            return today...maxTime
        }

        // For subsequent slots, constrain based on what came before
        if index > 0 {
            let prevSlotTime = calendar.date(from: slots[index - 1]) ?? today
            let minTime = calendar.date(byAdding: .second, value: Int(buffer), to: prevSlotTime) ?? today

            // For the last slot, also check wrap-around to first slot
            if index == slots.count - 1 {
                let firstSlotTime = calendar.date(from: slots[0]) ?? today
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? today
                let maxTimeBeforeWrap = calendar.date(byAdding: .second, value: -Int(buffer), to: endOfDay.addingTimeInterval(firstSlotTime.timeIntervalSince(today))) ?? endOfDay

                // Ensure valid range
                guard maxTimeBeforeWrap >= minTime else { return nil }

                return minTime...maxTimeBeforeWrap
            }

            // For middle slots, constrain by next slot too
            if index < slots.count - 1 {
                let nextSlotTime = calendar.date(from: slots[index + 1]) ?? today
                let maxTime = calendar.date(byAdding: .second, value: -Int(buffer), to: nextSlotTime) ?? today

                // Ensure valid range
                guard maxTime >= minTime else { return nil }

                return minTime...maxTime
            }

            // Last slot only constrained by previous
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            return minTime...endOfDay
        }

        return nil // First slot with no others, no constraint
    }

    private func binding(for index: Int) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: slots[index]) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                slots[index] = components
                onSlotsChanged()
            }
        )
    }
}

struct NotificationSlotsEditor_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var slots: [DateComponents] = [
            DateComponents(hour: 9, minute: 0),
            DateComponents(hour: 21, minute: 0)
        ]

        let schedule = ReviewSchedule.expanding(
            ExpandingIntervalSchedule(
                id: UUID(),
                name: "Morning & Evening",
                intervals: [1, 2, 3, 5, 8],
                defaultSlots: [
                    DateComponents(hour: 9, minute: 0),
                    DateComponents(hour: 21, minute: 0)
                ],
                minimumSlotBuffer: 60 * 60 * 4, // 4 hours
                slotLabels: ["Morning", "Evening"]
            )
        )

        var body: some View {
            NavigationStack {
                List {
                    NotificationSlotsEditor(
                        slots: $slots,
                        schedule: schedule,
                        onSlotsChanged: {
                            print("Slots changed: \(slots)")
                        }
                    )
                }
            }
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
