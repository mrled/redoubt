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
