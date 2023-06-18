//
//  DevNotifications.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import SwiftUI

struct DevNotifications: View {
    @EnvironmentObject var notificationsModel: NotificationsViewModel
    @StateObject var notificationList = NotificationList()
    
    var body: some View {
        VStack {
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
                    if (notificationsModel.regularIntervalEntries + notificationsModel.oneTimeEntries).isEmpty {
                        Text("No saved notifications")
                    } else {
                        ForEach(notificationsModel.regularIntervalEntries, id: \.description) { entry in
                            Text("Interval: " + entry.description)
                        }
                        ForEach(notificationsModel.oneTimeEntries, id: \.description) { entry in
                            Text("One time: " + entry.description)
                        }
                    }
                }
                
                Section(header: Text("Notification actions")) {
                    Button("Refresh Notifications") {
                        notificationList.refreshNotifications()
                        notificationsModel.load()
                    }
                    Button("Notify me when minute changes") {
                        notificationsModel.oneTimeEntries.append(Calendar.current.dateComponents([.hour, .minute], from: Date().addingTimeInterval(60)))
                        notificationList.refreshNotifications()
                    }
                    Button("Notify me in five seconds") {
                        notificationsModel.oneTimeEntries.append(Calendar.current.dateComponents([.hour, .minute, .second], from: Date().addingTimeInterval(5)))
                        notificationList.refreshNotifications()
                    }
                    Button("Delete All Notifications") {
                        notificationsModel.deleteAllData()
                        notificationList.refreshNotifications()
                    }
                    .foregroundColor(.red)
                }
                
            }
        }
        .navigationBarTitle("Notifications debugger")
    }
}

struct DevNotifications_Previews: PreviewProvider {
    static let notificationsViewModel = NotificationsViewModel(dataLoader: NotificationsVmDataLoaderFromArray(schedules: [], oneTimes: []))
    static var previews: some View {
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                DevNotifications()
                    .environmentObject(notificationsViewModel)
            }
    }
}
