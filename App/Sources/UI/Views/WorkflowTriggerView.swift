import SwiftUI
import ZenViewKit

struct WorkflowTriggerView: View {
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
          .padding(6)
          .frame(maxWidth: .infinity)
        })
        .buttonStyle(.zen(.init(color: .systemBlue, grayscaleEffect: .constant(true))))

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
          .padding(6)
          .frame(maxWidth: .infinity)
        })
        .buttonStyle(.zen(.init(color: .systemCyan, grayscaleEffect: .constant(true))))
      }
      .frame(maxWidth: .infinity)
      .padding(8)
      .background(Color(.gridColor))
      .cornerRadius(8)
    }
    .buttonStyle(.regular)
  }
}

struct WorkflowTriggerView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowTriggerView(onAction: { _ in })
  }
}
