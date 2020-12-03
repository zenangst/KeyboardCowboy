import SwiftUI
import ModelKit

struct KeyboardRecorderView: View {
  @Binding var keyboardShortcut: ModelKit.KeyboardShortcut?

  var body: some View {
    Recorder(keyboardShortcut: $keyboardShortcut)
  }
}

// MARK: - Previews

struct KeyboardRecorderView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardRecorderView(keyboardShortcut: .constant(ModelFactory().keyboardShortcuts().first!))
      .frame(width: 320)
  }
}
