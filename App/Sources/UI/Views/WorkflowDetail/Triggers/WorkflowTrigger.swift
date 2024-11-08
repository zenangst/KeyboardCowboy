import Bonzai
import Inject
import SwiftUI

struct WorkflowTrigger: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @ObserveInjection var inject
  @Binding private var isGrayscale: Bool
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding, isGrayscale: Binding<Bool>) {
    _isGrayscale = isGrayscale
    self.focus = focus
  }

  var body: some View {
    VStack {
      HStack {
        TriggersIconView(size: 24)

        ZenDivider(.vertical)
          .frame(height: 24)

        FocusableButton(
          focus,
          identity: .detail(.addAppTrigger),
          variant: .zen(.init(calm: false,
                              color: .systemBlue,
                              focusEffect: .constant(true),
                              grayscaleEffect: $isGrayscale)),
          action: {
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .application([])
            }
          }
        ) {
          HStack(spacing: 6) {
            GenericAppIconView(size: 20)
            Text("Application")
              .font(.caption)
              .lineLimit(1)
          }
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
          variant: .zen(.init(calm: false,
                              color: .systemIndigo,
                              focusEffect: .constant(true),
                              grayscaleEffect: $isGrayscale)),
          action: {
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(KeyboardShortcutTrigger(passthrough: false, holdDuration: nil, shortcuts: []))
            }
          }
        ) {
          HStack(spacing: 6) {
            KeyboardIconView("M", size: 20)
            Text("Keyboard Shortcut")
              .allowsTightening(true)
              .lineLimit(1)
              .font(.caption)
          }
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
          variant: .zen(.init(calm: false,
                              color: .systemPurple,
                              focusEffect: .constant(true),
                              grayscaleEffect: $isGrayscale)),
          action: {
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .snippet(SnippetTrigger(id: UUID().uuidString, text: ""))
            }
            focus.wrappedValue = .detail(.snippet)
          }
        ) {

          
          HStack(spacing: 6) {
            SnippetIconView(size: 20)
            Text("Snippet")
              .font(.caption)
              .lineLimit(1)
          }
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
      .roundedContainer(padding: 8, margin: 0)
    }
    .buttonStyle(.regular)
    .enableInjection()
  }
}

#Preview {
  @FocusState var focus: AppFocus?
  return WorkflowTrigger($focus, isGrayscale: .constant(true))
    .designTime()
}
