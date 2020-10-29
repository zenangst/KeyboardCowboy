import SwiftUI
import ModelKit

public struct KeyboardShortcutListView: View {
  public enum Action {
    case createKeyboardShortcut(ModelKit.KeyboardShortcut, index: Int, in: Workflow)
    case updateKeyboardShortcut(ModelKit.KeyboardShortcut, in: Workflow)
    case deleteKeyboardShortcut(ModelKit.KeyboardShortcut, in: Workflow)
    case moveCommand(ModelKit.KeyboardShortcut, to: Int, in: Workflow)
  }

  let keyboardShortcutController: KeyboardShortcutController
  let keyboardShortcuts: [ModelKit.KeyboardShortcut]
  let workflow: Workflow

  public var body: some View {
    VStack {
      ForEach(Array(keyboardShortcuts.enumerated()), id: \.element) { index, keyboardShortcut in
        MovableView(element: keyboardShortcut, dragHandler: { offset, _ in
          let indexOffset = Int(round(offset.height / 48))
          keyboardShortcutController.perform(.moveCommand(keyboardShortcut, to: indexOffset, in: workflow))
        }, {
          HStack {
            Text("\(index + 1)").padding(.horizontal, 4)
            KeyboardShortcutView(keyboardShortcut: Binding<ModelKit.KeyboardShortcut?>(get: {
              keyboardShortcut
            }, set: { keyboardShortcut in
              if let keyboardShortcut = keyboardShortcut {
                keyboardShortcutController.perform(.updateKeyboardShortcut(keyboardShortcut, in: workflow))
              }
            }))
            HStack(spacing: 4) {
              Button("+", action: {
                if let index = keyboardShortcuts.firstIndex(of: keyboardShortcut) {
                  keyboardShortcutController.perform(.createKeyboardShortcut(KeyboardShortcut.empty(),
                                                                             index: index + 1,
                                                                             in: workflow))
                }
              })
              Button("-", action: {
                keyboardShortcutController.perform(.deleteKeyboardShortcut(keyboardShortcut, in: workflow))
              })
            }
          }
          .padding(.horizontal, 8)
          .frame(height: 48, alignment: .center)
          .background(Color(.windowBackgroundColor))
          .cornerRadius(8)
          .padding(.horizontal)
          .shadow(color: Color(.shadowColor).opacity(0.15), radius: 3, x: 0, y: 1)
        })
      }
    }
  }
}

// MARK: - Previews

struct KeyboardShortcutListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutListView(
      keyboardShortcutController: KeyboardShortcutPreviewController().erase(),
      keyboardShortcuts: ModelFactory().keyboardShortcuts(),
      workflow: ModelFactory().workflowDetail())
  }
}
