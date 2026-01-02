import Foundation


/// A collection of secrets and notifications about them
struct SecretCollection: Codable {
    let secrets: [Secret]
    let regularIntervalNotifications: [DateComponents]
    let oneTimeNotifications: [DateComponents]
    let spacedRepetitionCategories: [SpacedRepetitionCategory]
}
