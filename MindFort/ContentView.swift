//
//  ContentView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-22.
//

import SwiftUI
import CryptoKit


struct ContentView: View {
    @Binding var secrets: [HashedSecret]
//    @Binding var showingAddSecret: Bool
    
    @State var showingAddSecret: Bool = false

    var body: some View {
        HashedSecretView(secrets: $secrets)
    }


}
