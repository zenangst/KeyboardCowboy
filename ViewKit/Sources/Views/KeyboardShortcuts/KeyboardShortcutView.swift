import SwiftUI

struct KeyboardShortcutView: View {
  let combination: KeyboardShortcutViewModel

  var body: some View {
    HStack {
      Text(combination.name)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
      Button("Clear", action: {})
        .font(.caption)
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondaryLabelColor))
        .foregroundColor(.white)
        .cornerRadius(36)
    }
    .padding(.horizontal, 4)
    .background(Color(.textBackgroundColor))
    .cornerRadius(36)
  }
}

// MARK: - Previews

struct KeyboardShortcutView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutView(combination: ModelFactory().keyboardShortcuts().first!)
      .frame(width: 320)
  }
}
