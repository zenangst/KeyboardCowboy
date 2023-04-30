import SwiftUI

struct OnboardingScene: Scene {
  var body: some Scene {
    WindowGroup(id: KeyboardCowboy.onboardingWindowIdentifier) {
      OnboardingView()
        .toolbar(content: {
          Spacer()
          Text("Permissions")
          Spacer()
        })
        .frame(width: 480, height: 420)
    }
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified(showsTitle: true))
    .windowStyle(.hiddenTitleBar)
  }
}
