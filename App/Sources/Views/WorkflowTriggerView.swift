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
      HStack(spacing: 16) {
        Button(action: { onAction(.addApplication) }, label: {
          VStack(spacing: 8) {
            Image(systemName: "app.dashed")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16)
            Text("Add Application")
              .lineLimit(1)
          }
        })

        Button(action: { onAction(.addKeyboardShortcut) }, label: {
          VStack(spacing: 8) {
            Image(systemName: "command")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 16)
            Text("Keyboard Shortcut")
          }
        })
        Spacer()
      }
      .padding(16)
      .background(Color(nsColor: .gridColor))
      .cornerRadius(8)
    }
    .buttonStyle(.appStyle)
    .enableInjection()
  }
}
