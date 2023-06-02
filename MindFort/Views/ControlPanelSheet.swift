//
//  DeveloperSheet.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import SwiftUI

struct PlaygroundButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        HStack {
                Text(label)
                Spacer()
                Button("Generate") { action() }
                    .buttonStyle(DefaultButtonStyle())
        }
    }
}

struct ControlPanelSheet: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @StateObject var notificationList = NotificationList()
    
    var body: some View {
        VStack {
            Text("Secret control panel")
                .font(.title)
                .bold()
                .padding()
            List {
                Section(header: Text("Notifications from Notification Center")) {
                    if notificationList.notifications.isEmpty {
                        Text("No registered notifications")
                    } else {
                        ForEach(notificationList.notifications) { item in
                            VStack(alignment: .leading) {
                                Text(item.title)
                                Text(item.body)
                                Text(item.id)
                                Text("Next trigger: \(item.trigger?.nextTriggerDate()?.description ?? "Never")")
                            }
                        }
                    }
                }
                .onAppear {
                    notificationList.refreshNotifications()
                }

                Section(header: Text("Notifications from ViewModel")) {
                    let allCalendarNotifications = notificationsModel.regularIntervalEntries + notificationsModel.oneTimeEntries
                    if allCalendarNotifications.isEmpty {
                        Text("No saved notifications")
                    } else {
                        ForEach(allCalendarNotifications, id: \.description) { entry in
                            Text(entry.description)
                        }
                    }
                }
                
                Section(header: Text("Notification actions")) {
                    Button("Refresh Notifications") {
                        notificationList.refreshNotifications()
                        notificationsModel.load()
                    }
                    Button("Add notification for one minute from now") {
                        notificationsModel.oneTimeEntries.append(Calendar.current.dateComponents([.hour, .minute], from: Date().addingTimeInterval(60)))
                        notificationList.refreshNotifications()
                    }
                    Button("Delete All Notifications") {
                        notificationsModel.deleteAllData()
                        notificationList.refreshNotifications()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Haptic feedback playground")) {
                    PlaygroundButton(label: "Impact: light") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: medium") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: heavy") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: rigid") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: soft") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Notification: success") {
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.success)
                    }
                    PlaygroundButton(label: "Notification: warning") {
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.warning)
                    }
                    PlaygroundButton(label: "Notification: error") {
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.error)
                    }
                    PlaygroundButton(label: "Selection: changed") {
                        let feedbackGenerator = UISelectionFeedbackGenerator()
                        feedbackGenerator.selectionChanged()
                    }
                }
            }
        }
    }
}

struct DeveloperSheet_Previews: PreviewProvider {
    static let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
    static var previews: some View {
        ControlPanelSheet()
            .environmentObject(notificationsViewModel)
    }
}
