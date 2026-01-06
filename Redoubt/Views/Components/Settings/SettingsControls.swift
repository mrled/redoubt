import SwiftUI
import Foundation

struct SettingsControls: View {
    @Binding var showOnboarding: Bool
    @Binding var showDeveloperOptions: Bool
    @Binding var enableEasterEggs: Bool
    @Binding var visualizationMode: VisualizationMode
    @Binding var demoMode: Bool
    var body: some View {
        Section("Settings") {
            // Not sure if it's the Toggles or what, but the spacing doesn't match RowItemWithIcon.
            // Just make them all HStack{Image, Text} and they look the same.
            Toggle(isOn: $showOnboarding) {
                // is a RowItemWithIcon except the Icon is a ShimmeringSystemImage
                HStack {
                    ShimmeringSystemImage(systemName: "play")
                        .frame(width: 32, height: 32)
                    Text("Show the onboarding button")
                }
            }
            Toggle(isOn: $enableEasterEggs) {
                HStack {
                    Image(systemName: "sparkles")
                        .frame(width: 32, height: 32)
                    Text("Enable easter eggs")
                }
            }
            HStack {
                Image(systemName: "sparkles.tv")
                    .frame(width: 32, height: 32)
                Picker(selection: $visualizationMode, label: Text("Visualization type")) {
                    ForEach(VisualizationMode.allCases) { possibleVizMode in
                        Text(possibleVizMode.description).tag(possibleVizMode)
                    }
                }
            }
            Toggle(isOn: $showDeveloperOptions) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 32, height: 32)
                    Text("Show developer options")
                }
            }
            NavigationLink(destination: DemoModeSheet(isPresentingDemoMode: .constant(false))) {
                HStack {
                    Image(systemName: "tv")
                        .frame(width: 32, height: 32)
                    if demoMode {
                        Text("Demo mode (currently enabled)")
                    } else {
                        Text("Demo mode (currently disabled)")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            SettingsControls(
                showOnboarding: .constant(true),
                showDeveloperOptions: .constant(false),
                enableEasterEggs: .constant(true),
                visualizationMode: .constant(.Sha512),
                demoMode: .constant(false)
            )
        }
    }
}
