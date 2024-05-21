import SwiftUI

struct EmptyConfigurationWindow: Scene {
  @Namespace var namespace
  private let onAction: (EmptyConfigurationView.Action) -> Void

  init(onAction: @escaping (EmptyConfigurationView.Action) -> Void) {
    self.onAction = onAction
  }

  var body: some Scene {
    WindowGroup(id: KeyboardCowboy.emptyConfigurationWindowIdentifier) {
      EmptyConfigurationView(namespace, onAction: onAction)
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
  }
}
