import Foundation
import Combine


class SecretsViewModel: ObservableObject {
    /// The type of notification schedule
    @Published var scheduleType: ScheduleType = .daily

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
    
    /// Categories for spaced repetition
    @Published var spacedRepetitionCategories: [SpacedRepetitionCategory] = [
        SpacedRepetitionCategory(name: "Daily", description: "", duration: 60 * 60 * 24),
        SpacedRepetitionCategory(name: "Every 3 days", description: "", duration: 60 * 60 * 24 * 3),
        SpacedRepetitionCategory(name: "Weekly", description: "", duration: 60 * 60 * 24 * 7),
        SpacedRepetitionCategory(name: "Every 2 weeks", description: "", duration: 60 * 60 * 24 * 7 * 2),
        SpacedRepetitionCategory(name: "Monthly", description: "", duration: 60 * 60 * 24 * 31),
    ] {
        didSet {
            dataManager.saveItems()
            publisherManager.setupPublishers()
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
    
    func addSpacedRepCategory(_ category: SpacedRepetitionCategory) {
        spacedRepetitionCategories.append(category)
        publisherManager.addSpacedRepCategoryPublisher(category)
    }

    func removeSpacedRepCategory(_ category: SpacedRepetitionCategory) {
        if let index = spacedRepetitionCategories.firstIndex(of: category) {
            spacedRepetitionCategories.remove(at: index)
            publisherManager.removeSpacedRepCategoryPublisher(category)
        }
    }

}
