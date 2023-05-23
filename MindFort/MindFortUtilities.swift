//
//  MindFortUtilities.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import Foundation

/// A convenience function for preview  functions
func unwrappedValue<T, E: Error>(_ result: Result<T, E>) -> T {
    try! result.get()
}
