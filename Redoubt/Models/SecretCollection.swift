import Foundation


/// A collection of secrets and notifications about them
struct SecretCollection: Codable {
    let secrets: [Secret]
    let regularIntervalNotifications: [DateComponents]
    let oneTimeNotifications: [DateComponents]
    let spacedRepetitionCategories: [SpacedRepetitionCategory]

    // New schedule system fields
    let availableSchedules: [ReviewSchedule]
    let activeScheduleId: UUID?
    let notificationSlots: [DateComponents]?

    enum CodingKeys: String, CodingKey {
        case secrets
        case regularIntervalNotifications
        case oneTimeNotifications
        case spacedRepetitionCategories
        case availableSchedules
        case activeScheduleId
        case notificationSlots
    }

    init(secrets: [Secret],
         regularIntervalNotifications: [DateComponents],
         oneTimeNotifications: [DateComponents],
         spacedRepetitionCategories: [SpacedRepetitionCategory],
         availableSchedules: [ReviewSchedule] = [.expanding(.default)],
         activeScheduleId: UUID? = nil,
         notificationSlots: [DateComponents]? = nil) {
        self.secrets = secrets
        self.regularIntervalNotifications = regularIntervalNotifications
        self.oneTimeNotifications = oneTimeNotifications
        self.spacedRepetitionCategories = spacedRepetitionCategories
        self.availableSchedules = availableSchedules
        self.activeScheduleId = activeScheduleId
        self.notificationSlots = notificationSlots
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        secrets = try container.decode([Secret].self, forKey: .secrets)
        regularIntervalNotifications = try container.decode([DateComponents].self, forKey: .regularIntervalNotifications)
        oneTimeNotifications = try container.decode([DateComponents].self, forKey: .oneTimeNotifications)
        spacedRepetitionCategories = try container.decode([SpacedRepetitionCategory].self, forKey: .spacedRepetitionCategories)

        // Provide defaults for new fields for backward compatibility
        availableSchedules = try container.decodeIfPresent([ReviewSchedule].self, forKey: .availableSchedules) ?? [.expanding(.default)]
        activeScheduleId = try container.decodeIfPresent(UUID.self, forKey: .activeScheduleId)
        notificationSlots = try container.decodeIfPresent([DateComponents].self, forKey: .notificationSlots)
    }
}
