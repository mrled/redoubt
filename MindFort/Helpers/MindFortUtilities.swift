import Foundation

/// A convenience function for preview functions
func unwrappedValue<T, E: Error>(_ result: Result<T, E>) -> T {
    try! result.get()
}
