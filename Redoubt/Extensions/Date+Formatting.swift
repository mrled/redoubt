import Foundation

extension Date {
    func mfFormatted(as format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    static func mfFromString(_ string: String?, format: String) -> Date? {
        guard let string else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if let date = dateFormatter.date(from: string) {
            return date
        } else {
            return nil
        }
    }
}
