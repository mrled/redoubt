import Foundation


enum VisualizationMode: String, Codable, CaseIterable, Identifiable {
    case Sha512

    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .Sha512: return "SHA512 hash"
        }
    }
}
