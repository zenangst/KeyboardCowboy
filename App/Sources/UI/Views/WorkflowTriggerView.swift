import SwiftUI
import Bonzai

struct WorkflowTriggerView: View {
  enum Action {
    case addApplication
    case addKeyboardShortcut
    case removeKeyboardShortcut
  }

  @Binding private var isGrayscale: Bool
  @FocusState private var focus: AppFocus?
  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>,
       isGrayscale: Binding<Bool>,
       onAction: @escaping (Action) -> Void
  ) {
    _isGrayscale = isGrayscale
    _focus = focus
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
        .buttonStyle(.zen(.init(color: .systemBlue, grayscaleEffect: $isGrayscale)))

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
        .buttonStyle(.zen(.init(color: .systemCyan, grayscaleEffect: $isGrayscale)))
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
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowTriggerView(_focus, isGrayscale: .constant(true), onAction: { _ in })
  }
}
