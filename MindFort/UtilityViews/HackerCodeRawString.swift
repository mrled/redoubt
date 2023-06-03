//
//  HackerCodeRawString.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-03.
//

import SwiftUI

struct HackerCodeRawString: View {
    @Binding var rawString: String
    
    /// Passed to groupCharacters()
    var perGroup = 4
    var perLine = 4
    
    /// Control display
    var fontSize: CGFloat = 10
    var foregroundColor: Color? = nil
    
    var prettyString: String {
        return groupCharacters(string: rawString, perGroup: perGroup, perLine: perLine)
    }
    
    var body: some View {
        Text(prettyString)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundColor(foregroundColor)
    }
}


struct HackerCodeRawString_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HackerCodeRawString(rawString: .constant(placeholderString.joined(separator: "")))
                .previewDisplayName("Placeholder")
        }
    }
}
