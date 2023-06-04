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

    /// A string password to display the hash of.
    /// If this is empty, we display a placeholder instead of a hash of nothing.
    /// If easter eggs are enabled and this string matches an easter egg, display the easter egg value instead of the hash of the input.
    @Binding var password: String
    
    var perGroup = 4
    var perLine = 4
    var fontSize: CGFloat = 10
    var foregroundColor: Color? = nil
    
    /// If this is False, we don't do any easter eggin'
    @AppStorage(MFAStorage.K.enableEasterEggs) var enableEasterEggs: Bool = MFAStorage.D.enableEasterEggs

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

    private var rawString: Binding<String> {
        Binding(
            get: {
                if enableEasterEggs, let easterEggCode = easterEggPasswords[password] {
                    return easterEggCode.joined(separator: "")
                } else if password.count > 0, let unwrappedHashData = hashData {
                    return data2hex(unwrappedHashData)
                } else {
                    return placeholderString.joined(separator: "")
                }
            },
            /// Writing to this wouldn't make any sense, we just ignore
            set: { _ in }
        )
    }
    
    var body: some View {
        HackerCodeRawString(rawString: rawString, perGroup: perGroup, perLine: perLine, fontSize: fontSize, foregroundColor: foregroundColor)
    }
}


struct H4XX0RC0D3_Previews: PreviewProvider {
    
    static var previews: some View {
        
        let userDefaultsEnableEasterEggs: UserDefaults = {
            let d = UserDefaults(suiteName: "userDefaultsEnableEasterEggs")!
            d.set(true, forKey: MFAStorage.K.enableEasterEggs)
            return d
            
        }()

        Group {
            H4XX0RC0D3(password: .constant("password"))
                .previewDisplayName("Password")
            H4XX0RC0D3(password: .constant("hunter2"))
                .previewDisplayName("AzureDiamond without EE")
            H4XX0RC0D3(password: .constant("hunter2"))
                .previewDisplayName("AzureDiamond with EE")
                .defaultAppStorage(userDefaultsEnableEasterEggs)

        }
    }
}
