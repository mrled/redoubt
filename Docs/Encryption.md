#  Encryption

How to securely store the passphrase?

* Prototype is just using SHA512
    * For passwords long enough to matter, this is actually pretty good. Probably shouldn't ship it though.
* Can I have the Secre Enclave handle it?
    * It can generate a NIST P256 key in the SE, which it does not allow to be exported
    * There's no SE support for a hash function though
* I could combine the plaintext with a long randomly generated key before hashing
    * Encrypt the long key with the SE
    * This is basically like adding a gigantic salt lol
* Hash _collisions_ don't actually matter :) because I'm not protecting anything with the passphrase; the passphrase is what needs protecting.
* Maybe I want HKDF? https://developer.apple.com/documentation/cryptokit/hkdf
    * I guess it's not intended for human passwords: https://stackoverflow.com/questions/67747650/password-hashing-using-cryptokit
* Swift PBKDF2 implementation, probably a bad idea to just copy code off of SO https://stackoverflow.com/questions/40336819/how-to-use-commoncrypto-for-pbkdf2-in-swift-2-3
    * This is using Apple code but I can't find any documentation? 
    * https://opensource.apple.com/source/CommonCrypto/CommonCrypto-60049/include/CommonKeyDerivation.h.auto.html
* I can get scrypt from CryptoSwift https://github.com/krzyzanowskim/CryptoSwift
    * Not a fan of third party libraries, but worth considering
* Secure Enclave pros
    * Side channel resistance
    * jj
