//
//  RowItemUrlWithIcon.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI

struct RowItemUrlWithIcon: View {
    var rowItem: RowItemWithIcon
    var destination: URL
    
    init(title: String, systemImageName: String, destination: URL) {
        rowItem = RowItemWithIcon(title: title, systemImageName: systemImageName)
        self.destination = destination
    }
    
    init(title: String, emoji: String, destination: URL) {
        rowItem = RowItemWithIcon(title: title, emoji: emoji)
        self.destination = destination
    }

    var body: some View {
        Link(destination: destination) {
            rowItem
        }
    }

}

struct RowItemUrlWithIcon_Previews: PreviewProvider {
    static let exampleUrl = URL(string: "https://example.com")!
    static var previews: some View {
        List {
            RowItemUrlWithIcon(title: "Example image", systemImageName: "moon", destination: exampleUrl)
            RowItemUrlWithIcon(title: "Example emoji", emoji: "🔮", destination: exampleUrl)
        }

    }
}
