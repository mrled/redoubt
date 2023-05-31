//
//  TimeRangePicker.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import SwiftUI

/// Expected to be placed in a List
struct TimeRangePicker: View {
    @State private var isStartExpanded = false
    @State private var isEndExpanded = false
    @State private var selectedStartTime = Date()
    @State private var selectedEndTime = Date()
    
    var body: some View {
        HStack {
            Text("Between")
            
            Button(action: {
                isEndExpanded = false
                isStartExpanded.toggle()
            }) {
                Text(formatTime(selectedStartTime))
                    .foregroundColor(Color.blue)
            }
            .buttonStyle(BorderedButtonStyle())
            
            Text("and")
            
            Button(action: {
                isStartExpanded = false
                isEndExpanded.toggle()
            }) {
                Text(formatTime(selectedEndTime))
                    .foregroundColor(Color.blue)
            }
            .buttonStyle(BorderedButtonStyle())
        }
        
        if isStartExpanded {
            VStack {
                Text("Start time")
                    .padding()
                DatePicker(selection: $selectedStartTime, displayedComponents: .hourAndMinute) {
                    Text("")
                }
                .labelsHidden()
                .datePickerStyle(WheelDatePickerStyle())
            }
        }
        
        if isEndExpanded {
            VStack {
                Text("End time")
                    .padding()
                DatePicker(selection: $selectedEndTime, displayedComponents: .hourAndMinute) {
                    Text("")
                }
                .labelsHidden()
                .datePickerStyle(WheelDatePickerStyle())
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct TimeRangePicker_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TimeRangePicker()
        }
    }
}
