import SwiftUI

struct WorkflowTriggerView: View {
  @ObserveInjection var inject
  enum Action {
    case addApplication
    case addKeyboardShortcut
    case removeKeyboardShortcut
  }

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    VStack {
      HStack {
        Button(action: { onAction(.addApplication) }, label: {
          HStack(spacing: 8) {
            Image(systemName: "app.dashed")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 12)
            Text("Application")
              .lineLimit(1)
          }
          .padding(8)
          .frame(maxWidth: .infinity)
        })
        .buttonStyle(GradientButtonStyle(.init(nsColor: .systemBlue)))

        Spacer()

        Button(action: { onAction(.addKeyboardShortcut) }, label: {
          HStack(spacing: 8) {
            Image(systemName: "command")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 12)
            Text("Keyboard Shortcut")
              .lineLimit(1)
          }
          .padding(8)
          .frame(maxWidth: .infinity)
        })
        .buttonStyle(GradientButtonStyle(.init(nsColor: .purple)))
      }
      .frame(maxWidth: .infinity)
      .padding(8)
      .background(Color(.gridColor))
      .cornerRadius(8)
    }
    .buttonStyle(.appStyle)
    .enableInjection()
  }
}
