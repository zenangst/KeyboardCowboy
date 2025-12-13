import Bonzai
import HotSwiftUI
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
      HStack(spacing: 6) {
        TriggersIconView(size: 24)

        FocusableButton(
          focus,
          identity: .detail(.addAppTrigger),
          action: {
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .application([])
            }
          },
          label: {
            HStack(spacing: 6) {
              GenericAppIconView(size: 20)
              Text("Application")
                .font(.caption)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 24)
          },
        )
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
          action: {
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .keyboardShortcuts(KeyboardShortcutTrigger(allowRepeat: false, passthrough: false, holdDuration: nil, shortcuts: []))
            }
          },
          label: {
            HStack(spacing: 6) {
              KeyboardIconView("M", size: 20)
              Text("Keyboard Shortcut")
                .allowsTightening(true)
                .lineLimit(1)
                .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 24)
          },
        )
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
          action: {
            updater.modifyWorkflow(using: transaction) { workflow in
              workflow.trigger = .snippet(SnippetTrigger(id: UUID().uuidString, text: ""))
            }
            focus.wrappedValue = .detail(.snippet)
          },
          label: {
            HStack(spacing: 6) {
              SnippetIconView(size: 20)
              Text("Snippet")
                .font(.caption)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 24)
          },
        )
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
      .roundedStyle(padding: 6)
      .environment(\.buttonBackgroundColor, .gray)
    }
    .enableInjection()
  }
}

#Preview {
  @FocusState var focus: AppFocus?
  return WorkflowTrigger($focus, isGrayscale: .constant(true))
    .designTime()
}
