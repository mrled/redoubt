//
//  ShimmeringSystemImage.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-04.
//

import SwiftUI

struct ShimmeringSystemImage: View {
    var systemName: String
    @State private var isShimmering = false
//    @State private var gradientColors: [Color] = [Color.purple, Color.red.opacity(0.5), Color.blue]
    @State private var gradientColors: [Color] = [Color.red, Color.green, Color.blue]

//    var body: some View {
//        LinearGradient(
//            gradient: Gradient(colors: gradientColors),
//            startPoint: .leading,
//            endPoint: .trailing
//        )
//        .mask(
//            Image(systemName: systemName)
//                .foregroundColor(.white)
//        )
//        .onAppear {
//            withAnimation(.linear(duration: 3)) {
//                isShimmering = true
//            }
//        }
//    }

    var body: some View {
        ZStack {
            withAnimation(.linear(duration: 3)) {
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Image(systemName: systemName)
                        .foregroundColor(.white)
                )
            }
        }
    }
}

struct ShimmeringSystemImage_Previews: PreviewProvider {
    static var previews: some View {
        ShimmeringSystemImage(systemName: "play")
            .frame(width: 100, height: 100)
    }
}
