import Foundation


/// A collection of secrets and notifications about them
struct SecretCollection: Codable {
    let secrets: [Secret]
    let regularIntervalNotifications: [DateComponents]
    let oneTimeNotifications: [DateComponents]

    // New schedule system fields
    let availableSchedules: [ReviewSchedule]
    let activeScheduleId: UUID?
    let notificationSlots: [DateComponents]?

    enum CodingKeys: String, CodingKey {
        case secrets
        case regularIntervalNotifications
        case oneTimeNotifications
        case availableSchedules
        case activeScheduleId
        case notificationSlots
    }

    init(secrets: [Secret],
         regularIntervalNotifications: [DateComponents],
         oneTimeNotifications: [DateComponents],
         availableSchedules: [ReviewSchedule] = [.expanding(.default), .expanding(.onceDaily)],
         activeScheduleId: UUID? = nil,
         notificationSlots: [DateComponents]? = nil) {
        self.secrets = secrets
        self.regularIntervalNotifications = regularIntervalNotifications
        self.oneTimeNotifications = oneTimeNotifications
        self.availableSchedules = availableSchedules
        self.activeScheduleId = activeScheduleId
        self.notificationSlots = notificationSlots
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        secrets = try container.decode([Secret].self, forKey: .secrets)
        regularIntervalNotifications = try container.decode([DateComponents].self, forKey: .regularIntervalNotifications)
        oneTimeNotifications = try container.decode([DateComponents].self, forKey: .oneTimeNotifications)

        // Provide defaults for new fields for backward compatibility
        availableSchedules = try container.decodeIfPresent([ReviewSchedule].self, forKey: .availableSchedules) ?? [.expanding(.default), .expanding(.onceDaily)]
        activeScheduleId = try container.decodeIfPresent(UUID.self, forKey: .activeScheduleId)
        notificationSlots = try container.decodeIfPresent([DateComponents].self, forKey: .notificationSlots)
    }
}
