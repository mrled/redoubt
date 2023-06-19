//
//  SpacedRepetitionCategory.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-18.
//

import Foundation


class SpacedRepetitionCategory: Identifiable, ObservableObject, Codable, Equatable {
    @Published var id: String
    @Published var name: String
    @Published var description: String
    @Published var duration: TimeInterval
    
    init(name: String, description: String, duration: TimeInterval) {
        id = name
        self.name = name
        self.description = description
        self.duration = duration
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, duration
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(duration, forKey: .duration)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedName = try container.decode(String.self, forKey: .name)
        id = decodedName
        name = decodedName
        description = try container.decode(String.self, forKey: .description)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
    }
    
    static func == (left: SpacedRepetitionCategory, right: SpacedRepetitionCategory) -> Bool {
        return left.id == right.id
    }
}

