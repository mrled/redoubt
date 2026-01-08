import Foundation


/// Get a list of passwords we can use in demo mode
func getDemoModeSecretCollection() -> SecretCollection {
    do {
        let secrets = [
            try Secret(name: "Password", plaintext: "password"),
            try Secret(name: "AzureDiamond", plaintext: "hunter2"),
            try Secret(name: "XKCD", plaintext: "correct horse battery staple"),
        ]
        return SecretCollection(secrets: secrets)
    } catch {
        return SecretCollection(secrets: [])
    }

}
