import SwiftUI

import Sodium

/// H4XX0R C0D3
/// This is:
///  - the hash block of the $password under normal circumstances
///  - a placeholder if the $password is empty
///  - an easter egg if the $password is one of the famous passwords
///
///  REMINDER: this is a view, you can't do expensive computations here!
///  (This obvious warning brought to you by the bruise I have on my forehead from banging my head against this for a week,
///  looking everywhere for the cause except here.)
///
/// The hash block is just for a fun visual - the input password is concatenated with a random value
/// so that if a shoulder is surfed or a screenshot is shared an attacker would not be able to guess.
struct H4XX0RC0D3: View {

    /// A string password to display the hash of.
    /// If this is empty, we display a placeholder instead of a hash of nothing.
    /// If easter eggs are enabled and this string matches an easter egg, display the easter egg value instead of the hash of the input.
    @Binding var password: String
    
    var perGroup = 4
    var perLine = 4
    var fontSize: CGFloat = 10
    var foregroundColor: Color? = nil
    
    @AppStorage(MFAStorage.K.enableEasterEggs) var enableEasterEggs: Bool = MFAStorage.D.enableEasterEggs
    @AppStorage(MFAStorage.K.visualizationMode) var visualizationMode: VisualizationMode = MFAStorage.D.visualizationMode
    
    private let sodium = Sodium()
    
    /// A random value to mix with our password so that the display is useless, even theoretically, for a shoulder surfer or screenshot
    private var ubersalt: Bytes? {
        return sodium.randomBytes.buf(length: 128)
    }
    
    private var displayHash: String? {
        if password.count == 0 {
            return nil
        }
        guard let unwrappedUbersalt = ubersalt else {
            return nil
        }
        guard let passwordData = password.data(using: .utf8) else {
            return nil
        }
        
        switch visualizationMode {
        case .Sha512:
            let hash = sha512(data: unwrappedUbersalt + passwordData)
            let hexHash = data2hex(hash)
            return hexHash
        }
    }

    private var rawString: Binding<String> {
        Binding(
            get: {
                if enableEasterEggs, let easterEggCode = easterEggPasswords[password] {
                    return easterEggCode.joined(separator: "")
                } else if password.count > 0, let unwrappedDisplayHash = displayHash {
                    return unwrappedDisplayHash
                } else {
                    return placeholderStringArray.joined(separator: "")
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
