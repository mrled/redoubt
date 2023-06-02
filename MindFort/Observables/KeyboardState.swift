//
//  KeyboardState.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import Foundation
import SwiftUI


/// An observable object that holds information about keyboard state, whether it's showing or not, etc
class KeyboardState: ObservableObject {
    @Published var isKeyboardVisible = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Apparently this is undefined behavior, because it's publishing an observable from a view update. Bleh.
    @objc private func keyboardWillShow(notification: Notification) {
        isKeyboardVisible = true
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        isKeyboardVisible = false
    }
}

class MockKeyboardUpState: KeyboardState {
    override init() {
        super.init()
        self.isKeyboardVisible = true
    }
}

class MockKeyboardDownState: KeyboardState {
    override init() {
        super.init()
        self.isKeyboardVisible = false
    }
}
