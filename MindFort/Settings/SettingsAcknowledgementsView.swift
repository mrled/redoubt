//
//  SettingsAcknowledgementsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI

struct SettingsAcknowledgementsView: View {
    var body: some View {
        List {
            Section(header: Text("Inspiration")) {
                Text("First, thanks to Glyph for making PINPal, a command-line program written in Python designed to help you remember passwords via spaced repetition. I thought that was such a good idea that I wanted to make a mobile app that does the same thing.")
                RowItemUrlWithIcon(title: "glyph/PINPal", emoji: "🐙", destination: URL(string: "https://github.com/glyph/PINPal")!)
                RowItemUrlWithIcon(title: "PINPal announcement blog post", systemImageName: "network", destination: URL(string: "ttps://blog.glyph.im/2023/04/post-pycon-us-2023-notes.html")!)
            }
            Section(header: Text("Twemoji")) {
                Text("Thanks to Twitter for their excellent Twemoji open source emoji graphics, which I have used in this and many other projects.")
                RowItemUrlWithIcon(title: "Twemoji", systemImageName: "network", destination: URL(string: "ttps://blog.glyph.im/2023/04/post-pycon-us-2023-notes.html")!)
            }
        }
        .navigationTitle("Acknowledgements")
    }
}

struct SettingsAcknowledgementsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAcknowledgementsView()
    }
}
