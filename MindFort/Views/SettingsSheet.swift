//
//  SettingsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI

struct SettingsSheet: View {
    @AppStorage("showControlPanel") var showControlPanel: Bool = false
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .bold()
                .padding()
            List {
                Toggle(isOn: $showControlPanel) {
                    Text("Show secret developer control panel")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet()
    }
}
