import SwiftUI

public struct KeyboardShortcutListView: View {
  public enum Action {
    // Add index to create method
    case createKeyboardShortcut(KeyboardShortcutViewModel, index: Int)
    case updateKeyboardShortcut(KeyboardShortcutViewModel)
    case deleteKeyboardShortcut(KeyboardShortcutViewModel)
    case moveCommand(from: Int, to: Int)
  }

  @ObservedObject var keyboardShortcutController: KeyboardShortcutController

  public var body: some View {
    List {
      ForEach(keyboardShortcutController.state) { keyboardShortcut in
        HStack {
          Text("\(keyboardShortcut.index).").padding(.horizontal, 4)
          KeyboardShortcutView(keyboardShortcut: Binding<KeyboardShortcutViewModel?>(
                                get: { keyboardShortcut },
                                set: { keyboardShortcut in
                                  if let keyboardShortcut = keyboardShortcut {
                                    keyboardShortcutController.perform(.updateKeyboardShortcut(keyboardShortcut))
                                  }
                                }))
          HStack(spacing: 4) {
            Button("+", action: {
                    keyboardShortcutController.perform(.createKeyboardShortcut(KeyboardShortcutViewModel.empty(),
                                                                               index: keyboardShortcut.index))
            })
            Button("-", action: { keyboardShortcutController.perform(.deleteKeyboardShortcut(keyboardShortcut)) })
          }
        }
        .frame(height: 36)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .cornerRadius(8.0)
        .tag(keyboardShortcut)
        Divider()
      }.onMove(perform: { indices, newOffset in
        for i in indices {
          keyboardShortcutController.perform(.moveCommand(from: i, to: newOffset))
        }
      }).onDelete(perform: { indexSet in
        for index in indexSet {
          let keyboardShortcut = keyboardShortcutController.state[index]
          keyboardShortcutController.perform(.deleteKeyboardShortcut(keyboardShortcut))
        }
      })

      if keyboardShortcutController.state.isEmpty {
        HStack(spacing: 2) {
          Spacer()
          Button("Add Keyboard Shortcut", action: {
            keyboardShortcutController.perform(.createKeyboardShortcut(KeyboardShortcutViewModel.empty(),
                                                                       index: keyboardShortcutController.state.count))
          })
          .buttonStyle(LinkButtonStyle())
        }
        .padding([.top, .trailing], 10)
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
    KeyboardShortcutListView(keyboardShortcutController: KeyboardShortcutPreviewController().erase())
  }
}

private final class KeyboardShortcutPreviewController: ViewController {
  let state = ModelFactory().keyboardShortcuts()
  func perform(_ action: KeyboardShortcutListView.Action) {}
}
