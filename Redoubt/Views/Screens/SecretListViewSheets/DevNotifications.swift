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

                Section(header: Text("Notification actions")) {
                    Button("Refresh Notifications") {
                        secretsVm.dataManager.loadItems()
                        notificationList.refreshNotifications()
                    }
                    Button("Re-register All Notifications") {
                        secretsVm.notificationManager.reregisterAllNotifications()
                        notificationList.refreshNotifications()
                    }
                }
                
            }
        }
        .navigationBarTitle("Notifications debugger")
    }
}

struct DevNotifications_Previews: PreviewProvider {
    static let exampleEmptyCollection = SecretCollection(secrets: [])
    static let secretsPreviewVm = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleEmptyCollection))
    static var previews: some View {
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                DevNotifications()
                    .environmentObject(secretsPreviewVm)
            }
    }
}
