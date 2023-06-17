//
//  UserDefaultsWrappers.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-17.
//
// via https://www.vadimbulavin.com/advanced-guide-to-userdefaults-in-swift/
//
// To use this:
// 1. Extend the UserDefaultsWrapperKey with the keys you want to use
//      extension UserDefaultsWrapperKey {
//        static let `isFirstLaunch`: UserDefaultsWrapperKey = "isFirstLaunch"
//      }
// 2. Place the values in some nice location for your app to reference, like a struct called 'Storage':
//      struct Storage {
//          @UserDefault(key: .isFirstLaunch, default: true)
//          var isFirstLaunch: Bool
//      }
// 3. Observe it with code like this -- note $-prefix when creating the observation:
//        var storage = Storage()
//        var observation = storage.$isFirstLaunch.observe { old, new in
//            print("Changed from: \(old) to \(new)")
//        }
//        storage.isFirstLaunch = true
//        storage.isFirstLaunch.toggle()

import Foundation


/// Make up a new empty protocol and apply it to everything that a plist supports.
/// As UserDefaults is based on plists, this also means everything that UserDefaults supports.
protocol PropertyListValue {}
extension Data: PropertyListValue {}
extension String: PropertyListValue {}
extension Date: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Float: PropertyListValue {}
// Every element must be a property-list type
extension Array: PropertyListValue where Element: PropertyListValue {}
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}


/// Implement a property wrapper which saves and loads values from UserDefaults.
/// It requires a default value.
@propertyWrapper
struct UserDefault<T: PropertyListValue> {
    let key: UserDefaultsWrapperKey
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            if let result = UserDefaults.standard.value(forKey: key.rawValue) {
                if let typedResult = result as? T {
                    return typedResult
                } else {
                    return defaultValue
                }
            } else {
                return defaultValue
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key.rawValue)
        }
    }
    
    /// projectedValue is "a projection of the binding value that returns a binding";
    /// it is what enables $-prefixed bindings.
    /// https://developer.apple.com/documentation/swiftui/binding/projectedvalue
    var projectedValue: UserDefault<T> { return self }
    
    /// Return an instance of the property wrapper
    func observe(change: @escaping (T?, T?) -> Void) -> NSObject {
        return DefaultsObservation(key: key) { old, new in
            change(old as? T, new as? T)
        }
    }
}


/// The key, representing a string that UserDefaults understands.
struct UserDefaultsWrapperKey: RawRepresentable {
    let rawValue: String
}

/// Allow creating new key objects with just a string
extension UserDefaultsWrapperKey: ExpressibleByStringLiteral {
    init(stringLiteral: String) {
        rawValue = stringLiteral
    }
}


/// An observation of a single UserDefaults key.
/// It listens to UserDefaults change via KVO.
class DefaultsObservation: NSObject {
    let key: UserDefaultsWrapperKey
    private var onChange: (Any, Any) -> Void

    init(key: UserDefaultsWrapperKey, onChange: @escaping (Any, Any) -> Void) {
        self.onChange = onChange
        self.key = key
        super.init()
        UserDefaults.standard.addObserver(self, forKeyPath: key.rawValue, options: [.old, .new], context: nil)
    }
    
    // This is called by the KVO system automatically when the value changes
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change, object != nil, keyPath == key.rawValue else { return }
        onChange(change[.oldKey] as Any, change[.newKey] as Any)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: key.rawValue, context: nil)
    }
}
