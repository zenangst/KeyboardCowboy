import SwiftUI
import ModelKit

public struct KeyboardShortcutListView: View {
  public enum Action {
    case createKeyboardShortcut(keyboardShortcut: ModelKit.KeyboardShortcut, index: Int)
    case updateKeyboardShortcut(keyboardShortcut: ModelKit.KeyboardShortcut)
    case deleteKeyboardShortcut(keyboardShortcut: ModelKit.KeyboardShortcut)
    case moveCommand(from: Int, to: Int)
  }

  @ObservedObject var keyboardShortcutController: KeyboardShortcutController

  public var body: some View {
    List {
      ForEach(Array(keyboardShortcutController.state.enumerated()), id: \.element) { index, keyboardShortcut in
        HStack {
          Text("\(index + 1)").padding(.horizontal, 4)
          KeyboardShortcutView(keyboardShortcut: Binding<ModelKit.KeyboardShortcut?>(get: {
            keyboardShortcut
          }, set: { keyboardShortcut in
            if let keyboardShortcut = keyboardShortcut {
              keyboardShortcutController.perform(.updateKeyboardShortcut(keyboardShortcut: keyboardShortcut))
            }
          }))
          HStack(spacing: 4) {
            Button("+", action: {
              if let index = keyboardShortcutController.state.firstIndex(of: keyboardShortcut) {
                keyboardShortcutController.perform(.createKeyboardShortcut(keyboardShortcut: KeyboardShortcut.empty(),
                                                                           index: index))
              }
            })
            Button("-", action: {
              keyboardShortcutController.perform(.deleteKeyboardShortcut(keyboardShortcut: keyboardShortcut))
            })
          }
        }
        .padding(8)
        .frame(height: 45)
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
          keyboardShortcutController.perform(.deleteKeyboardShortcut(keyboardShortcut: keyboardShortcut))
        }
      })
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
  let state: [ModelKit.KeyboardShortcut] = ModelFactory().keyboardShortcuts()
  func perform(_ action: KeyboardShortcutListView.Action) {}
}
