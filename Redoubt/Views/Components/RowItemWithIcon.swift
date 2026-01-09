import SwiftUI


struct RowItemWithIcon: View{
    var title: String
    // We have to use a closure because the icon could be one of several types of view.
    // A function can return AnyView, but a property cannot be "any View".
    // idk!!!
    var icon: () -> AnyView
    
    init(title: String, systemImageName: String) {
        self.title = title
        self.icon = { AnyView(Image(systemName: systemImageName)) }
    }
    
    init(title: String, emoji: String) {
        self.title = title
        self.icon = { AnyView(Text(emoji)) }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            self.icon()
                .frame(width: 32, height: 32)
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct RowItemWithIcon_Previews: PreviewProvider {
    static var previews: some View {
        List {
            RowItemWithIcon(title: "Example image", systemImageName: "moon")
            RowItemWithIcon(title: "Example emoji", emoji: "🔮")
        }
    }
}
