//
//  DeveloperSheet.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-30.
//

import SwiftUI

struct PlaygroundButton: View {
    let label: String
    let action: () -> Void
    var body: some View {
        HStack {
                Text(label)
                Spacer()
                Button("Generate") { action() }
                    .buttonStyle(DefaultButtonStyle())
        }
    }
}

struct DevHapticPlayground: View {
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Haptic feedback playground")) {
                    PlaygroundButton(label: "Impact: light") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: medium") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: heavy") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: rigid") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Impact: soft") {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
                        feedbackGenerator.impactOccurred()
                    }
                    PlaygroundButton(label: "Notification: success") {
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.success)
                    }
                    PlaygroundButton(label: "Notification: warning") {
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.warning)
                    }
                    PlaygroundButton(label: "Notification: error") {
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.error)
                    }
                    PlaygroundButton(label: "Selection: changed") {
                        let feedbackGenerator = UISelectionFeedbackGenerator()
                        feedbackGenerator.selectionChanged()
                    }
                }
            }
        }
        .navigationBarTitle("Haptic playground")
    }
}

struct DevHapticPlayground_Previews: PreviewProvider {
    static var previews: some View {
        Text("Root view")
            .sheet(isPresented: .constant(true)) {
                DevHapticPlayground()
            }
    }
}
