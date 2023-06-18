//
//  DayWeekMonthIntervalPicker.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-31.
//

import SwiftUI


enum TimeUnit: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { self.rawValue }
}


/// Pick intervals of a few days, a few weeks, or a few months.
struct DayWeekMonthIntervalPicker: View {
    @State var timeUnit: TimeUnit = .day

    var body: some View {
        HStack {
            Picker("Every", selection: $timeUnit) {
                ForEach(TimeUnit.allCases) { unit in
                    // You must include the .tag(unit), otherwise the underlying $timeUnit updates,
                    // but the view doesn't appear to have updated to the user.
                    Text("\(unit.rawValue)").tag(unit)
                }
            }
        }
    }
}


struct DayIntervalPicker_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Text("How often?")
            DayWeekMonthIntervalPicker()
        }
    }
}
