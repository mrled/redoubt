//
//  SecretCollection.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-18.
//

import Foundation


struct SecretCollection: Codable {
    let secrets: [Secret]
    let regularIntervalNotifications: [DateComponents]
    let oneTimeNotifications: [DateComponents]
    let spacedRepetitionCategories: [SpacedRepetitionCategory]
}
