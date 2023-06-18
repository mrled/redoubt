//
//  SpacedRepCategories.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-18.
//

import Foundation


struct SpacedRepCategory: Identifiable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
}


class SpacedRepCategoriesViewModel: ObservableObject {
    @Published var categories: [SpacedRepCategory] = [
        SpacedRepCategory(name: "Daily", duration: 60 * 60 * 24),
        SpacedRepCategory(name: "Every 3 days", duration: 60 * 60 * 24 * 3),
        SpacedRepCategory(name: "Weekly", duration: 60 * 60 * 24 * 7),
        SpacedRepCategory(name: "Every 2 weeks", duration: 60 * 60 * 24 * 7 * 2),
        SpacedRepCategory(name: "Monthly", duration: 60 * 60 * 24 * 31),
    ]
}

