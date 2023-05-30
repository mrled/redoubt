//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .bold()
                .padding()
            List {
                Section(header: Text("To do")) {
                    RowItemWithIcon(title: "Spaced repetition schedule editor", systemImageName: "clock")
                    RowItemWithIcon(title: "Option to disable HAXX0R C0D3", systemImageName: "laptopcomputer")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
