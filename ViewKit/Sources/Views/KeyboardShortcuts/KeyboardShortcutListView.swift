import SwiftUI

public struct KeyboardShortcutListView: View {
  public enum Action {
    case createKeyboardShortcut(viewModel: KeyboardShortcutViewModel, index: Int)
    case updateKeyboardShortcut(viewModel: KeyboardShortcutViewModel)
    case deleteKeyboardShortcut(viewModel: KeyboardShortcutViewModel)
    case moveCommand(from: Int, to: Int)
  }

  let keyboardShortcutController: KeyboardShortcutController

  public var body: some View {
    VStack(spacing: 0) {
      ForEach(keyboardShortcutController.state) { keyboardShortcut in
        HStack {
          Text("1.").padding(.horizontal, 4)
          KeyboardShortcutView(keyboardShortcut: .constant(keyboardShortcut))
          HStack(spacing: 4) {
            Button("+", action: {  })
            Button("-", action: {  })
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
          keyboardShortcutController.perform(.deleteKeyboardShortcut(viewModel: keyboardShortcut))
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
  let state: [KeyboardShortcutViewModel] = ModelFactory().keyboardShortcuts()
  func perform(_ action: KeyboardShortcutListView.Action) {}
}
