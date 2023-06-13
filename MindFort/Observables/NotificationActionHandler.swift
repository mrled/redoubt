//
//  NotificationActionHandler.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-13.
//

import Foundation


enum OpenAction: String {
    case home
    case startQuiz
}


class NotificationActionHandler: ObservableObject {
    static let shared = NotificationActionHandler()
    
    @Published var openAction: OpenAction? = .home
    
    private init() { }
    
    func handleNotificationAction(_ action: String) {
        if let openAction = OpenAction(rawValue: action) {
            self.openAction = openAction
        } else {
            self.openAction = .home
        }
    }
}
