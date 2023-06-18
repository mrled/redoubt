//
//  TimePickerExpandable.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-31.
//

import SwiftUI


struct TimePickerExpandable: View {
    @State var label: String = "At"
    @Binding var date: Date
    @State var expanded: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
                Button(action: {
                    expanded.toggle()
                }) {
                    Text(formatTime(date))
                        .foregroundColor(Color.blue)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            if expanded {
                VStack {
                    Text("Add a new time")
                        .padding()
                    DatePicker(selection: $date, displayedComponents: .hourAndMinute) {
                        Text("")
                    }
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct TimePickerExpandable_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TimePickerExpandable(date: .constant(Date()))
            TimePickerExpandable(label: "The illustrious time of: ", date: .constant(Date()))
        }
    }
}
