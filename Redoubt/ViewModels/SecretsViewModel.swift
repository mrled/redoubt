import Foundation
import Combine


class SecretsViewModel: ObservableObject {
    /// All secrets that the user has entered
    @Published var secrets: [Secret] = [] {
        didSet {
            dataManager.saveItems()
            publisherManager.setupPublishers()
        }
    }

    /// Repeating, user-configured times to send notifications
    @Published var regularIntervalNotifications: [DateComponents] = [] {
        didSet {
            dataManager.saveItems()
        }
    }
    
    /// Non-repeating, user-configured times to send notifications
    @Published var oneTimeNotifications: [DateComponents] = [] {
        didSet {
            dataManager.saveItems()
        }
    }

    // New schedule system properties
    /// Available review schedules
    @Published var availableSchedules: [ReviewSchedule] = [
        .expanding(.default),
        .expanding(.onceDaily)
    ] {
        didSet {
            dataManager.saveItems()
        }
    }

    /// ID of the currently active schedule (nil = notifications disabled)
    @Published var activeScheduleId: UUID? = nil {
        didSet {
            dataManager.saveItems()
        }
    }

    /// User-customized notification slots (nil = use schedule defaults)
    @Published var notificationSlots: [DateComponents]? = nil {
        didSet {
            dataManager.saveItems()
        }
    }

    /// Secrets that are currently due for review based on the active schedule
    var secretsDue: [Secret] {
        guard let scheduleId = activeScheduleId,
              let schedule = availableSchedules.first(where: { $0.id == scheduleId }) else {
            return []
        }
        return secrets.filter { secret in
            guard let dueDate = schedule.nextReviewDate(
                lastQuizzed: secret.lastQuizzed,
                consecutiveSuccesses: secret.consecutiveSuccesses
            ) else { return false }
            return dueDate <= Date()
        }
    }

    /// Manager for notification scheduling and handling
    let notificationManager = SecretsNotificationManager()
    
    /// Manager for data loading, saving, and demo mode handling
    let dataManager: SecretsDataManager
    
    /// Manager for publisher setup and cancellables
    let publisherManager = SecretsPublisherManager()

    
    init(dataLoader: SecretsVmDataLoader? = nil) {
        // Initialize data manager with optional dataLoader
        dataManager = SecretsDataManager(dataLoader: dataLoader)
        
        // Set up relationships between managers and view model
        dataManager.setSecretsViewModel(self)
        notificationManager.setSecretsViewModel(self)
        publisherManager.setSecretsViewModel(self)
        
        // Load data and setup publishers
        dataManager.loadItems()
        publisherManager.setupPublishers()
    }
    
    func addSecret(_ secret: Secret) {
        secrets.append(secret)
        publisherManager.addSecretPublisher(secret)
    }

    func removeSecret(_ secret: Secret) {
        if let index = secrets.firstIndex(of: secret) {
            secrets.remove(at: index)
            publisherManager.removeSecretPublisher(secret)
        }
    }

}
