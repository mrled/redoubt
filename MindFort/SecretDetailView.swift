//
//  HashedSecretDetailView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-28.
//

import SwiftUI

struct SecretDetailView: View {
    let secret: HashedSecret
    @State private var passphrase = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            TextField("Passphrase", text: $passphrase)
                .keyboardType(.default)
                .focused($isFocused)
                .padding()
            Spacer()
            Text("H4XX0R C0D3")
                .font(.headline)
            Text(prettyHashBlock(digest: secret.digest, perLine: 4))
                .font(.system(size: 14, design: .monospaced))
                .padding()
            Spacer()
        }
        .padding()
        .navigationBarTitle(secret.name)
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
}


struct HashedSecretDetailView_Previews: PreviewProvider {
    static let secret = try! HashedSecret(name: "Test Secret", value: "hunter2")
    static var previews: some View {
        SecretDetailView(secret: secret)
    }
}
