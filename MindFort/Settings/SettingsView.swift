//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section(header: Text("About")) {
                NavigationLink(destination: SettingsAcknowledgementsView(), label: {
                    RowItemWithIcon(title: "Acknowledgements", systemImageName: "list.bullet.rectangle.portrait.fill")
                })
            }
            Section(header: Text("To do")) {
                RowItemWithIcon(title: "Spaced repetition schedule editor", systemImageName: "clock")
                RowItemWithIcon(title: "Option to disable HAXX0R C0D3", systemImageName: "laptopcomputer")
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
