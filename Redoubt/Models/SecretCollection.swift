import Foundation


/// A collection of secrets and notifications about them
struct SecretCollection: Codable {
    let secrets: [Secret]

    // Schedule-based notification system
    let availableSchedules: [ReviewSchedule]
    let activeScheduleId: UUID?
    let notificationSlots: [DateComponents]?

    enum CodingKeys: String, CodingKey {
        case secrets
        case availableSchedules
        case activeScheduleId
        case notificationSlots
    }

    init(secrets: [Secret],
         availableSchedules: [ReviewSchedule] = [.expanding(.default), .expanding(.onceDaily)],
         activeScheduleId: UUID? = nil,
         notificationSlots: [DateComponents]? = nil) {
        self.secrets = secrets
        self.availableSchedules = availableSchedules
        self.activeScheduleId = activeScheduleId
        self.notificationSlots = notificationSlots
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        secrets = try container.decode([Secret].self, forKey: .secrets)

        // Provide defaults for backward compatibility
        availableSchedules = try container.decodeIfPresent([ReviewSchedule].self, forKey: .availableSchedules) ?? [.expanding(.default), .expanding(.onceDaily)]
        activeScheduleId = try container.decodeIfPresent(UUID.self, forKey: .activeScheduleId)
        notificationSlots = try container.decodeIfPresent([DateComponents].self, forKey: .notificationSlots)
    }
}
