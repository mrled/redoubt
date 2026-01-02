import SwiftUI

struct DevNotifications: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
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
                    if (secretsVm.regularIntervalNotifications + secretsVm.oneTimeNotifications).isEmpty {
                        Text("No saved notifications")
                    } else {
                        ForEach(secretsVm.regularIntervalNotifications, id: \.description) { entry in
                            Text("Interval: " + entry.description)
                        }
                        ForEach(secretsVm.oneTimeNotifications, id: \.description) { entry in
                            Text("One time: " + entry.description)
                        }
                    }
                }
                
                Section(header: Text("Notification actions")) {
                    Button("Refresh Notifications") {
                        secretsVm.dataManager.loadItems()
                        notificationList.refreshNotifications()
                    }
                    Button("Notify me when minute changes") {
                        secretsVm.oneTimeNotifications.append(Calendar.current.dateComponents([.hour, .minute], from: Date().addingTimeInterval(60)))
                        secretsVm.dataManager.loadItems()
                        notificationList.refreshNotifications()
                    }
                    Button("Notify me in five seconds") {
                        secretsVm.oneTimeNotifications.append(Calendar.current.dateComponents([.hour, .minute, .second], from: Date().addingTimeInterval(5)))
                        secretsVm.dataManager.loadItems()
                        notificationList.refreshNotifications()
                    }
                    Button("Delete All Notifications") {
                        secretsVm.oneTimeNotifications = []
                        secretsVm.regularIntervalNotifications = []
                        secretsVm.dataManager.saveItems()
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
    static let exampleEmptyCollection = SecretCollection(secrets: [], regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
    static let secretsPreviewVm = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleEmptyCollection))
    static var previews: some View {
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                DevNotifications()
                    .environmentObject(secretsPreviewVm)
            }
    }
}
