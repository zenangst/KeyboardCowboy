import Bonzai
import Inject
import SwiftUI

struct WorkflowTriggerView: View {
  enum Action {
    case addApplication
    case addKeyboardShortcut
    case addSnippet
    case removeKeyboardShortcut
  }

  @ObserveInjection var inject
  @Binding private var isGrayscale: Bool
  private let onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       isGrayscale: Binding<Bool>,
       onAction: @escaping (Action) -> Void
  ) {
    _isGrayscale = isGrayscale
    self.focus = focus
    self.onAction = onAction
  }

  var body: some View {
    VStack {
      HStack {
        FocusableButton(
          focus,
          identity: .detail(.addAppTrigger),
          variant: .zen(.init(color: .systemBlue, 
                              focusEffect: .constant(true),
                              grayscaleEffect: $isGrayscale)),
          action: { onAction(.addApplication) }
        ) {
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
        }
        .onMoveCommand(perform: { direction in
          switch direction {
          case .right:
            focus.wrappedValue = .detail(.addKeyboardTrigger)
          default: break
          }
        })


        FocusableButton(
          focus,
          identity: .detail(.addKeyboardTrigger),
          variant: .zen(.init(color: .systemIndigo,
                              focusEffect: .constant(true),
                              grayscaleEffect: $isGrayscale)),
          action: {
            onAction(.addKeyboardShortcut)
          }
        ) {
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
        }
        .onMoveCommand(perform: { direction in
          switch direction {
          case .left:
            focus.wrappedValue = .detail(.addAppTrigger)
          case .right:
            focus.wrappedValue = .detail(.addSnippetTrigger)
          default: break
          }
        })

        FocusableButton(
          focus,
          identity: .detail(.addSnippetTrigger),
          variant: .zen(.init(color: .systemPurple,
                              focusEffect: .constant(true),
                              grayscaleEffect: $isGrayscale)),
          action: { onAction(.addSnippet) }
        ) {
          HStack(spacing: 8) {
            Image(systemName: "heart.text.square.fill")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 12)
            Text("Snippet")
              .lineLimit(1)
          }
          .padding(6)
          .frame(maxWidth: .infinity)
        }
        .onMoveCommand(perform: { direction in
          switch direction {
          case .left:
            focus.wrappedValue = .detail(.addKeyboardTrigger)
          default: break
          }
        })
      }
      .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
        focus.wrappedValue = .detail(.commands)
      })
      .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
        focus.wrappedValue = .detail(.name)
      })
      .frame(maxWidth: .infinity)
      .padding(8)
      .background(Color(.gridColor))
      .cornerRadius(8)
    }
    .buttonStyle(.regular)
    .enableInjection()
  }
}

struct WorkflowTriggerView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowTriggerView($focus, isGrayscale: .constant(true), onAction: { _ in })
  }
}
