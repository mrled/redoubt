//
//  DemoNavbarToolbarButton.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-17.
//

import SwiftUI

struct DemoNavbarToolbarButton: View {
    @AppStorage(MFAStorage.K.demoMode) private var demoMode: Bool = MFAStorage.D.demoMode
    @State private var isPresentingDemoModeSheet = false
    var body: some View {
        if demoMode {
            Button(action: { isPresentingDemoModeSheet = true }) {
                Text("DEMO")
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            .sheet(isPresented: $isPresentingDemoModeSheet) {
                DemoModeSheet(isPresentingDemoMode: $isPresentingDemoModeSheet)
            }
        }
    }
}

struct DemoNavbarToolbarButton_Previews: PreviewProvider {
    static var previews: some View {
        DemoNavbarToolbarButton()
    }
}
