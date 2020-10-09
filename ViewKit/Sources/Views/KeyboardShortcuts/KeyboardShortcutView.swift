import SwiftUI

struct KeyboardShortcutView: View {
  @Binding var keyboardShortcut: KeyboardShortcutViewModel?

  var body: some View {
    HStack(spacing: 0) {
      Recorder(keyboardShortcut: $keyboardShortcut)
    }
    .padding(.horizontal, 4)
    .cornerRadius(6)
  }
}

// MARK: - Previews

struct KeyboardShortcutView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutView(keyboardShortcut: .constant(ModelFactory().keyboardShortcuts().first!))
      .frame(width: 320)
  }
}
