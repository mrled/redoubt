//
//  MindFortContext.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-17.
//

import Foundation


/// Get a list of passwords we can use in demo mode
func getDemoModePasswords() -> [Secret] {
    do {
        return [
            try Secret(name: "Password", plaintext: "password"),
            try Secret(name: "AzureDiamond", plaintext: "hunter2"),
            try Secret(name: "XKCD", plaintext: "correct horse battery staple"),
        ]
    } catch {
        return []
    }

}
