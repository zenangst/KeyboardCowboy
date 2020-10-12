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
        .padding(8)
        .frame(height: 36)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8.0)
        .tag(keyboardShortcut)
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
    }
    .padding(.horizontal, -18)
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
