import SwiftUI

struct VizTypeSheet: View {
    @EnvironmentObject var secretsVm: SecretsViewModel
    @Binding var visualizationMode: VisualizationMode
    
    var body: some View {
        VStack {
            NavigationView {
                List {
                    Section(
                        footer: Text("The visualization shown during password entry.")
                    ) {
                        HStack {
                            Image(systemName: "sparkles.tv")
                                .frame(width: 32, height: 32)
                            Picker(selection: $visualizationMode, label: Text("Visualization type")) {
                                ForEach(VisualizationMode.allCases) { possibleVizMode in
                                    Text(possibleVizMode.description).tag(possibleVizMode)
                                }
                            }
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note that for hash types, random data is mixed in with user input.")
                            Text("This prevents a captured image of the screen from revealing any information about the password, but also means that you cannot use Redoubt as a hash generator.")
                                .padding(.top, 8)

                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .navigationBarTitle("Visualization Type", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DemoNavbarToolbarButton()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VizTypeSheet(
            visualizationMode: .constant(.Sha512),
        )
    }
    .environmentObject(SecretsViewModel())
}
