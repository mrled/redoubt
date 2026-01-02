import SwiftUI

struct ShimmeringSystemImage: View {
    var systemName: String
    @State private var gradientColors: [Color] = [Color.red, Color.green, Color.blue]

    var body: some View {
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

struct ShimmeringSystemImage_Previews: PreviewProvider {
    static var previews: some View {
        ShimmeringSystemImage(systemName: "play")
            .frame(width: 100, height: 100)
    }
}
