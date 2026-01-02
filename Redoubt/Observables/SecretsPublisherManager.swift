import Foundation
import Combine

/**
 * Manages the Combine Publishers (which are the Swift pub/sub concept) for secrets and categories to trigger data saves.
 *
 * Sets up individual publishers on reference type objects since @Published only
 * detects array-level changes, not mutations within array elements.
 */
class SecretsPublisherManager: ObservableObject {
    weak var secretsViewModel: SecretsViewModel?
    
    /// We listen to changes to UserDefaults using NotificationManager
    /// Keep track of cancellables from NotificationManager here
    var cancellables: [ObjectIdentifier : AnyCancellable] = [:]
    
    init() {
        
    }
    
    func setSecretsViewModel(_ viewModel: SecretsViewModel) {
        self.secretsViewModel = viewModel
    }
    
    /// Set a publisher for each observable.
    /// Whenever any items in the secrets or spacedRepetitionCategories changes, it triggers saveItems().
    ///
    /// Note the difference between the @Published property wrapper and what we do here.
    /// @Published will allow observation of any changes to the property itself,
    /// and we set @Published on all of the arrays we want to be observable.
    /// So far so good.
    /// However, for properties which are arrays, when an item IN the array mutates without mutating the array itself,
    /// @Published does not see this change.
    ///
    /// Structs are passed by value.
    /// For arrays of value types like structs,
    /// changes to any item in the array results in a new copy of the array.
    /// In this case, @Published sees the change, and we have nothing to do here.
    /// That's why this function doesn't need to do anything with our regularIntervalNotifications or oneTimeNotifications properties.
    ///
    /// However, class instances are passed by reference.
    /// For arrays of reference types like class instances,
    /// mutation of an item in the array can be done in place, without making a new copy of the array,
    /// which means that @Published cannot see that there was a change.
    /// Therefore, this function needs to iterate through each class instance in our secrets and spacedRepetitionCategories properties,
    /// and set up publishers on each instance individually in order to be notified when they are changed.
    ///
    /// We keep track of the cancellables so that we can throw away publishers for items we no longer need.
    /// When an item is added or deleted from the array of reference types with .addX or .removeX,
    /// we handle the publishers and cancellables there.
    /// This function handles loading new data, such as initialization time or if we swap to demo mode.
    ///
    /// Warnings:
    /// - If a reference type is replaced with a totally new instance, we will not detect it
    /// - If an array containing reference types is modified directly rather than through .addX or .removeX, we will not detect the change
    func setupPublishers() {
        guard let viewModel = secretsViewModel else { return }
        
        // Cancel any existing publishers
        cancellables.forEach { $0.value.cancel() }
        cancellables.removeAll()

        viewModel.secrets.forEach { secret in
            let secretCancellable = secret.objectWillChange
                .sink { [weak self] _ in
                    self?.secretsViewModel?.dataManager.saveItems()
                }
            cancellables[ObjectIdentifier(secret)] = secretCancellable
        }
        
        viewModel.spacedRepetitionCategories.forEach { category in
            let categoryCancellable = category.objectWillChange
                .sink { [weak self] _ in
                    self?.secretsViewModel?.dataManager.saveItems()
                }
            cancellables[ObjectIdentifier(category)] = categoryCancellable
        }
    }
    
    func addSecretPublisher(_ secret: Secret) {
        let cancellable = secret.objectWillChange
            .sink { [weak self] _ in
                self?.secretsViewModel?.dataManager.saveItems()
            }
        cancellables[ObjectIdentifier(secret)] = cancellable
    }
    
    func removeSecretPublisher(_ secret: Secret) {
        cancellables[ObjectIdentifier(secret)]?.cancel()
        cancellables[ObjectIdentifier(secret)] = nil
    }
    
    func addSpacedRepCategoryPublisher(_ category: SpacedRepetitionCategory) {
        let cancellable = category.objectWillChange
            .sink { [weak self] _ in
                self?.secretsViewModel?.dataManager.saveItems()
            }
        cancellables[ObjectIdentifier(category)] = cancellable
    }
    
    func removeSpacedRepCategoryPublisher(_ category: SpacedRepetitionCategory) {
        cancellables[ObjectIdentifier(category)]?.cancel()
        cancellables[ObjectIdentifier(category)] = nil
    }
}
