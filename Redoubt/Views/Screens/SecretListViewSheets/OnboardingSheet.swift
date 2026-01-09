import SwiftUI

struct OnboardingSheet: View {
    @Binding var isPresentingOnboardingSheet: Bool
    @AppStorage(MFAStorage.K.showOnboarding) var showOnboarding: Bool = MFAStorage.D.showOnboarding
    @AppStorage(MFAStorage.K.onboardingHasShownOnce) var onboardingHasShownOnce: Bool = MFAStorage.D.onboardingHasShownOnce

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer() // The spacers center content horizontally even though the parent VStack is alignment:.leading
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                Text("Redoubt")
                    .font(.title)
                    .bold()
                    .padding()
                Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                Spacer()
            }
            HStack {
                Text("Remember your most important passwords: your password database, GPG key, or Monero wallet.")
                    .font(.title2)
                    .padding([.top, .bottom])
            }
            Group {
                VStack(alignment: .leading) {
                    Text("How it works")
                        .font(.title2)
                        .padding([.top, .bottom])
                }
                RowItemWithIcon(title: "Save passwords you must not forget", systemImageName: "list.bullet")
                RowItemWithIcon(title: "Receive periodic notifications to quiz yourself", systemImageName: "bell")
                // TODO: update this when spaced repetition is added
                RowItemWithIcon(title: "Enter your passwords correctly and the time until the next quiz increases", systemImageName: "calendar")
            }

            Group {
                Text("Redoubt is secure")
                    .font(.title2)
                    .padding([.top, .bottom])
                VStack(alignment: .leading) {
                    RowItemWithIcon(title: "Passwords are saved with strong hashing via Argon2, not stored in plaintext", systemImageName: "lock.shield")
                    RowItemWithIcon(title: "Hashes live only on your device, not synced or backed up", systemImageName: "lock.iphone")
                }
            }
            Group {
                Text("Enable permissions")
                    .font(.title2)
                    .padding([.top, .bottom])
                HStack(spacing: 20) {
                    PermissionButton(
                        title: "Notifications",
                        systemImageName: "bell.fill",
                        permissionType: .notifications
                    )
                }
                .padding([.bottom])
            }
            Spacer()
            Divider()
            Button(action: dismissOnboarding) {
                Text("Dismiss onboarding")
            }
            .padding([.top])
            Text("Re-enable this onboaring screen in Settings")
                .font(.subheadline)
        }
        .padding()
        .onAppear() {
            onboardingHasShownOnce = true
        }
    }
    
    func dismissOnboarding() {
        showOnboarding = false
        isPresentingOnboardingSheet = false
    }
}

struct OnboardingSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("Root view")
                .sheet(isPresented: .constant(true)) {
                    OnboardingSheet(isPresentingOnboardingSheet: .constant(true))
                }
                .previewDisplayName("Onboarding")
        }
    }
}
