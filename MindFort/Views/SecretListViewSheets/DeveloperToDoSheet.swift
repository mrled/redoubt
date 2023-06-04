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
            Text("To do list")
                .font(.title)
                .bold()
                .padding()
            List {
                Section(header: Text("Add features")) {
                    RowItemWithIcon(title: "Spaced repetition schedule editor", systemImageName: "clock")
                    RowItemWithIcon(title: "Try color schemes", systemImageName: "sparkles")
                    RowItemWithIcon(title: "Undo for deletes", systemImageName: "arrow.uturn.backward")
                    // https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files
                    // xcode project -> create capability -> Data Protection
                    RowItemWithIcon(title: "Use iOS Data Protection capability", systemImageName: "lock.doc")
                    RowItemWithIcon(title: "Add geofencing ability", systemImageName: "mappin.and.ellipse")
                    RowItemWithIcon(title: "Allow editing name of existing entries", systemImageName: "square.and.pencil")
                    RowItemWithIcon(title: "Use some good key derivation function for password storage", systemImageName: "lock")
                    RowItemWithIcon(title: "Keyboard shortcuts, at least enter to create, maybe escape to go back", systemImageName: "return")
                }
                Section(header: Text("Fix bugs")) {
                    RowItemWithIcon(title: "Tapping on notification should launch quiz", systemImageName: "ladybug")
                    RowItemWithIcon(title: "Prune past non-repeating notifications when loading/etc", systemImageName: "ladybug")
                    RowItemWithIcon(title: "Move notifications enablement to onboarding", systemImageName: "ladybug")
                }
                Section(header: Text("Done")) {
                    /// Remember: can't have more than 10 subviews. lol!
                    Group {
                        RowItemWithIcon(title: "Implement notifications", systemImageName: "bell")
                        RowItemWithIcon(title: "Show all of H4XX0R C0D3 w/ keyboard enabled", systemImageName: "ladybug")
                        RowItemWithIcon(title: "Add previous/next buttons to detail view", systemImageName: "arrow.right")
                        RowItemWithIcon(title: "Option to disable HAXX0R C0D3", systemImageName: "laptopcomputer")
                        RowItemWithIcon(title: "Are you sure? for deletes", systemImageName: "questionmark.circle")
                        RowItemWithIcon(title: "Add single place for AppStorage defaults and keys", systemImageName: "externaldrive")
                        RowItemWithIcon(title: "Fix entering quiz, exiting, then re-entering causes invalid secret (unsolveable)", systemImageName: "ladybug")
                        RowItemWithIcon(title: "Add the quiz functionality", systemImageName: "questionmark.app.dashed")
                        RowItemWithIcon(title: "Fix focus in quiz mode", systemImageName: "ladybug")
                        RowItemWithIcon(title: "Add a quiz complete screen", systemImageName: "questionmark.app.dashed")
                    }
                    Group {
                        RowItemWithIcon(title: "Add badge to Settings button if notifications are not enabled", systemImageName: "star.circle")
                        RowItemWithIcon(title: "Add onboarding screen", systemImageName: "star.circle")
                    }
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
