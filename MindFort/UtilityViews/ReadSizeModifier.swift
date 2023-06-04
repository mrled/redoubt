//
//  ReadSizeModifier.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-04.
//

import SwiftUI


/// Read the size of some element, and return the 
struct ReadSize: ViewModifier {
    @Binding var size: CGSize
    var logPrefix: String = ""
    
    var finalPrefix: String {
        logPrefix.count > 0 ? "ReadSize \(logPrefix):" : "ReadSize:"
    }
    
    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            })
            .onPreferenceChange(SizePreferenceKey.self) { size in
                self.size = size
            }
            .onAppear {
                print("\(finalPrefix) size is \(size) (FYI, scale is \(UIScreen.main.scale))")
            }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
