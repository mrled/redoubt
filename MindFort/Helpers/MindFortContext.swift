import Foundation


/// Get a list of passwords we can use in demo mode
func getDemoModeSecretCollection() -> SecretCollection {
    do {
        let secrets = [
            try Secret(name: "Password", plaintext: "password"),
            try Secret(name: "AzureDiamond", plaintext: "hunter2"),
            try Secret(name: "XKCD", plaintext: "correct horse battery staple"),
        ]
        let defaultCategories = [
            SpacedRepetitionCategory(name: "Daily", description: "", duration: 60 * 60 * 24),
            SpacedRepetitionCategory(name: "Every 3 days", description: "", duration: 60 * 60 * 24 * 3),
            SpacedRepetitionCategory(name: "Weekly", description: "", duration: 60 * 60 * 24 * 7),
            SpacedRepetitionCategory(name: "Every 2 weeks", description: "", duration: 60 * 60 * 24 * 7 * 2),
            SpacedRepetitionCategory(name: "Monthly", description: "", duration: 60 * 60 * 24 * 31),
        ]
        return SecretCollection(secrets: secrets, regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: defaultCategories)
    } catch {
        return SecretCollection(secrets: [], regularIntervalNotifications: [], oneTimeNotifications: [], spacedRepetitionCategories: [])
    }

}
