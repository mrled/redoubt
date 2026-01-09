import SwiftUI
import UserNotifications

struct DevNotifications: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    @StateObject var notificationList = NotificationList()

    // Computed properties for grouping notifications
    var devNotifications: [NotificationItem] {
        notificationList.notifications.filter { $0.id.hasPrefix("dev.") }
    }

    var quizNotifications: [NotificationItem] {
        notificationList.notifications.filter { $0.id.hasPrefix("quiz.") }
    }

    var body: some View {
        VStack {
            List {
                // Test notification controls
                Section(header: Text("Test Notifications")) {
                    Button("Notify me in 5 seconds") {
                        registerTestNotification(afterSeconds: 5)
                    }

                    Button("Notify me when minute changes") {
                        registerNotificationAtNextMinute()
                    }
                }

                // Selective deletion
                Section(header: Text("Delete Notifications")) {
                    Button("Delete All Dev Notifications") {
                        NotificationManager.shared.removeNotifications(prefix: "dev.")
                        notificationList.refreshNotifications()
                    }
                    .disabled(devNotifications.isEmpty)

                    Button("Delete All Quiz Notifications") {
                        NotificationManager.shared.removeNotifications(prefix: "quiz.")
                        notificationList.refreshNotifications()
                    }
                    .disabled(quizNotifications.isEmpty)
                }

                // Grouped notifications display
                Section(header: Text("Dev Notifications (\(devNotifications.count))")) {
                    if devNotifications.isEmpty {
                        Text("No dev notifications")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(devNotifications) { item in
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.body)
                                    .font(.subheadline)
                                Text(item.id)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Next trigger: \(item.trigger?.nextTriggerDate()?.description ?? "Never")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section(header: Text("Quiz Notifications (\(quizNotifications.count))")) {
                    if quizNotifications.isEmpty {
                        Text("No quiz notifications")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(quizNotifications) { item in
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.body)
                                    .font(.subheadline)
                                Text(item.id)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Next trigger: \(item.trigger?.nextTriggerDate()?.description ?? "Never")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
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

    // MARK: - Test Notification Helpers

    /// Register a test notification that fires after a specified number of seconds
    private func registerTestNotification(afterSeconds seconds: Int) {
        let triggerDate = Date().addingTimeInterval(TimeInterval(seconds))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)

        let identifier = notificationIdentifierFromDateComponents(components, prefix: "dev.test-")
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        NotificationManager.shared.registerNotification(
            title: "Test Notification",
            body: "This is a test notification from DevNotifications",
            identifier: identifier,
            trigger: trigger
        ) {
            notificationList.refreshNotifications()
        }
    }

    /// Register a test notification that fires at the next minute boundary
    private func registerNotificationAtNextMinute() {
        let now = Date()
        let calendar = Calendar.current

        // Get current time components
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)

        // Add one minute
        if let minute = components.minute {
            components.minute = minute + 1
        }
        components.second = 0

        let identifier = notificationIdentifierFromDateComponents(components, prefix: "dev.test-")
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        NotificationManager.shared.registerNotification(
            title: "Minute Change Test",
            body: "The minute just changed!",
            identifier: identifier,
            trigger: trigger
        ) {
            notificationList.refreshNotifications()
        }
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
