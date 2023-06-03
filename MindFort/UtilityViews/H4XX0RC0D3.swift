//
//  H4XX0RC0D3.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-02.
//

import SwiftUI

/// H4XX0R C0D3
/// This is:
///  - the hash block of the $password under normal circumstances
///  - a placeholder if the $password is empty
///  - an easter egg if the $password is one of the famous passwords
struct H4XX0RC0D3: View {
    @Binding var password: String
    var perGroup = 4
    var perLine = 4
    var fontSize: CGFloat = 10
    var foregroundColor: Color? = nil
    // TODO: have a global enum with default appstorage values
    @AppStorage(MFAStorage.K.enableEasterEggs) var enableEasterEggs: Bool = MFAStorage.D.enableEasterEggs

    var body: some View {
        Text(hashString)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundColor(foregroundColor)
    }
    
    private var hashData: Data? {
        if password.count == 0 {
            return nil
        }
        do {
            return try sha512(string: password)
        } catch {
            return nil
        }
    }
    
    private var hashString: String {
        if enableEasterEggs, let easterEggCode = easterEggPasswords[password] {
            return groupCharacters(string: easterEggCode.joined(separator: ""), perGroup: perGroup, perLine: perLine)
        }
        if password.count > 0, let unwrappedHashData = hashData {
            return prettyHashBlock(digest: unwrappedHashData, perGroup: perGroup, perLine: perLine)
        }
        return placeholderHashBlock(perGroup: perGroup, perLine: perLine)
    }
}


struct H4XX0RC0D3_Previews: PreviewProvider {
    // TODO: mock easter eggs=true
    static var previews: some View {
        Group {
            H4XX0RC0D3(password: .constant("password"))
                .previewDisplayName("Password")
            H4XX0RC0D3(password: .constant("correct horse battery staple"))
                .previewDisplayName("XKCD")
            H4XX0RC0D3(password: .constant("hunter2"))
                .previewDisplayName("AzureDiamond")
        }
    }
}
