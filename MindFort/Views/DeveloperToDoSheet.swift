//
//  DeveloperToDoSheet.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-02.
//

import SwiftUI

struct DeveloperToDoSheet: View {
    var body: some View {
        VStack {
            Text("Secret control panel")
                .font(.title)
                .bold()
                .padding()
            List {
                Section(header: Text("Add features")) {
                    RowItemWithIcon(title: "Spaced repetition schedule editor", systemImageName: "clock")
                    RowItemWithIcon(title: "Option to disable HAXX0R C0D3", systemImageName: "laptopcomputer")
                    RowItemWithIcon(title: "Try color schemes", systemImageName: "sparkles")
                    RowItemWithIcon(title: "Are you sure? for deletes", systemImageName: "questionmark.circle")
                    RowItemWithIcon(title: "Undo for deletes", systemImageName: "arrow.uturn.backward")
                    // https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files
                    // xcode project -> create capability -> Data Protection
                    RowItemWithIcon(title: "Use iOS Data Protection capability", systemImageName: "lock.doc")
                    RowItemWithIcon(title: "Add the quiz functionality", systemImageName: "questionmark.app.dashed")
                    RowItemWithIcon(title: "Add geofencing ability", systemImageName: "mappin.and.ellipse")
                    RowItemWithIcon(title: "Allow editing name of existing entries", systemImageName: "square.and.pencil")
                }
                Section(header: Text("Fix bugs")) {
                    RowItemWithIcon(title: "Tapping on notification should launch quiz", systemImageName: "ladybug")
                    RowItemWithIcon(title: "Prune past non-repeating notifications when loading/etc", systemImageName: "ladybug")
                }
                Section(header: Text("Done")) {
                    RowItemWithIcon(title: "Implement notifications", systemImageName: "bell")
                    RowItemWithIcon(title: "Show all of H4XX0R C0D3 w/ keyboard enabled", systemImageName: "ladybug")
                    RowItemWithIcon(title: "Add previous/next buttons to detail view", systemImageName: "arrow-right")
                }
            }
        }
    }
}

struct DeveloperToDoSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                DeveloperToDoSheet()
            }
    }
}
