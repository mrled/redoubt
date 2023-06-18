//
//  BinaryManipulation.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-08.
//

import Foundation


/// Return the input string in groups of characters and lines
func groupCharacters(string: String, perGroup: Int = 4, perLine: Int = 8) -> String {
    var result = ""
    var count = 0
    
    for (index, char) in string.enumerated() {
        result.append(char)
        
        if (index + 1) % perGroup == 0 {
            result.append(" ")
            count += 1
        }
        
        if count == perLine {
            result.append("\n")
            count = 0
        }
    }
    return result
}


/// Convert a
func data2hex(_ data: Data) -> String {
    return data.map { String(format: "%02x", $0) }.joined()
}


/// For all integers, including various Int8/UInt8/Int32/...etc, add a hexString property
/// Can be used on an array of integers to get a hex string, like this:
///     [1, 2, 3, 4, 5].map { $0.hexString }.joined()
protocol HexConvertible {
    var hexString: String { get }
}
extension BinaryInteger {
    var hexString: String {
        return String(self, radix: 16)
    }
}


/// Convert a hex string to a byte array
func hex2bytes(_ hexString: String) -> [UInt8] {
    var bytes = [UInt8]()
    var start = hexString.startIndex
    while start < hexString.endIndex {
        let end = hexString.index(start, offsetBy: 2)
        let byteString = hexString[start..<end]
        if let byte = UInt8(byteString, radix: 16) {
            bytes.append(byte)
        }
        start = end
    }
    return bytes
}


/// Given a SHA512 hash binary value, return a list of number groups
func prettyHashBlock(digest: Data, perGroup: Int = 4, perLine: Int = 8) -> String {
    return groupCharacters(string: data2hex(digest), perGroup: perGroup, perLine: perLine)
}
