//
//  DeveloperToDoSheet.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-02.
//

import SwiftUI


enum RoadmapItemType {
    case bug
    case feature
}


extension Date {
    func mfFormatted(as format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    static func mfFromString(_ string: String?, format: String) -> Date? {
        guard let string else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: string) {
            return date
        } else {
            return nil
        }
    }
}


struct RoadmapItem: Identifiable {
    var name: String
    var type: RoadmapItemType = .bug
    var icon: String = "ladybug"
    var done: Date? = nil
    var id: UUID = UUID()
    
    init(_ name: String, _ type: RoadmapItemType = .bug, icon: String? = nil, done: String? = nil) {
        self.name = name
        self.type = type
        if let icon {
            self.icon = icon
        } else {
            switch type {
            case .bug: self.icon = "ladybug"
            case .feature: self.icon = "star.circle"
            }
        }
        if let done {
            if let date = Date.mfFromString(done, format: "yyyyMMdd") {
                self.done = date
            }
        }
    }
}


struct RoadmapItemView: View {
    var name: String
    var icon: String
    var done: Date? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            VStack(alignment: .leading) {
                Text(name)
                if let done {
                    Text(done.mfFormatted(as: "yyyy-MM-dd"))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}


struct Roadmap: View {
    let items: [RoadmapItem] = [
        // features
        RoadmapItem("Spaced repetition schedule editor", .feature, icon: "clock"),
        RoadmapItem("Try color schemes", .feature, icon: "sparkles"),
        RoadmapItem("Add nice visualizations for password validation, animationms etc", .feature, icon: "sparkles"),
        RoadmapItem("Undo for deletes", .feature, icon: "arrow.uturn.backward"),
        // https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files
        // xcode project -> create capability -> Data Protection
        RoadmapItem("OS Data Protection capability", .feature, icon: "lock.doc"),
        RoadmapItem("Add geofencing ability", .feature, icon: "mappin.and.ellipse"),
        RoadmapItem("Allow editing name of existing entries", .feature, icon: "square.and.pencil"),

        // bugs
        RoadmapItem("Tapping on notification should launch quiz"),
        RoadmapItem("Prune past non-repeating notifications when loading/etc"),
        RoadmapItem("Move notifications enablement to onboarding"),
        RoadmapItem("Add onboarding note about visualizations: they're hash blocks, but mixed with randomness so they're just for fun"),

        // done
        RoadmapItem("Implement notifications", .feature, icon: "bell", done: "20230531"),
        RoadmapItem("Show all of H4XX0R C0D3 w/ keyboard enabled", done: "20230602"),
        RoadmapItem("Add previous/next buttons to detail view", .feature, icon: "arrow.right", done: "20230602"),
        RoadmapItem("Option to disable HAXX0R C0D3", .feature, icon: "laptopcomputer", done: "20230602"),
        RoadmapItem("Are you sure? for deletes", .feature, icon: "questionmark.circle", done: "20230602"),
        RoadmapItem("Add single place for AppStorage defaults and keys", .feature, icon: "externaldrive", done: "20230602"),
        RoadmapItem("Fix entering quiz, exiting, then re-entering causes invalid secret (unsolveable)", done: "20230603"),
        RoadmapItem("Add the quiz functionality", .feature, icon: "questionmark.app.dashed", done: "20230603"),
        RoadmapItem("Fix focus in quiz mode", done: "20230603"),
        RoadmapItem("Add a quiz complete screen", .feature, icon: "questionmark.app.dashed", done: "20230603"),
        RoadmapItem("Add badge to Settings button if notifications are not enabled", .feature, icon: "star.circle", done: "20230603"),
        RoadmapItem("Add onboarding screen", .feature, icon: "star.circle", done: "20230604"),
        RoadmapItem("Keyboard shortcuts, at least enter to create, maybe escape to go back", .feature, icon: "return", done: "20230604"),
        RoadmapItem("Slow validation speed when entering password", done: "20230613"),
        RoadmapItem("Use some good key derivation function for password storage", .feature, icon: "lock", done: "20230609"),
        RoadmapItem("Sometimes validation box briefly shows incorrect state before updating to correct state", done: "20230613"),
    ]
    var body: some View {
        VStack {
            List {
                Section(header: Text("Add features")) {
                    ForEach(items) { item in
                        if item.type == .feature && item.done == nil {
                            RoadmapItemView(name: item.name, icon: item.icon, done: item.done)
                        }
                    }
                }
                Section(header: Text("Fix bugs")) {
                    ForEach(items) { item in
                        if item.type == .bug && item.done == nil {
                            RoadmapItemView(name: item.name, icon: item.icon, done: item.done)
                        }
                    }
                }
                Section(header: Text("Done")) {
                    ForEach(items) { item in
                        if item.done != nil {
                            RoadmapItemView(name: item.name, icon: item.icon, done: item.done)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Roadmap")
    }
}

struct DeveloperToDoSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                NavigationView {
                    Roadmap()
                }
            }
    }
}
