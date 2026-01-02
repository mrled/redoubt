import Foundation
import os.log


enum CustomLogStream: String {
    case secretId
}


/// Log specific things for debugging
struct CustomLogger {
    
    /// Enable/disable various custom log types
    static let enabled: [CustomLogStream: Bool] = [
        .secretId: true
    ]
    
    /// Check if the stream is enabled and log if so
    private static func _log(stream: CustomLogStream, message: String) {
        if CustomLogger.enabled[stream] ?? false {
            print("[\(stream.rawValue)] \(message)")
        }
    }
    
    /// Individual logger functions (what we actually call elsewhere in the code)
    static func secretIds(message: String) {
        CustomLogger._log(stream: .secretId, message: message)
    }
}


let appLogger = Logger()
