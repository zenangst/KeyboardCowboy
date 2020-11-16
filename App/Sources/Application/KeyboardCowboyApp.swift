import SwiftUI

@main
struct KeyboardCowboyApp: App {
  // swiftlint:disable weak_delegate
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase
  @State var content: AnyView?

  var body: some Scene {
    WindowGroup {
      VStack {
        content
      }
      .frame(minWidth: 640, maxWidth: 1200,
             minHeight: 540, maxHeight: 1200)
      .onChange(of: scenePhase, perform: { _ in
        content = appDelegate.mainView?.environmentObject(appDelegate.userSelection).erase()
      })
    }.windowToolbarStyle(UnifiedWindowToolbarStyle())
  }
}
