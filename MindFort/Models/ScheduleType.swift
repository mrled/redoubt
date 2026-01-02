import Foundation


enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case disabled
    case daily
//    case weekly
//    case monthly
    case spacedRepetition
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .disabled: return "Disabled"
        case .daily: return "Every day"
        case .spacedRepetition: return "Spaced repetition"
        }
    }
}
