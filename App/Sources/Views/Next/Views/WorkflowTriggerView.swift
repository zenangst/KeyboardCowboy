import SwiftUI

struct WorkflowTriggerView: View {
  enum Action {
    case addApplication
    case addKeyboardShortcut
    case removeKeyboardShortcut
  }

  @ObserveInjection var inject
  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Button("Application", action: { onAction(.addApplication) })
        Button("Keyboard Shortcut", action: { onAction(.addKeyboardShortcut) })
        Spacer()
      }
    }
    .enableInjection()
  }
}
