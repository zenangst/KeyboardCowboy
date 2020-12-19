import SwiftUI
import ModelKit

struct KeyboardSequenceItem: View {
  let title: String
  let subtitle: String

  var body: some View {
    HStack(spacing: 0) {
      Text("\(title)")
      Text("\(subtitle)")
    }
    .padding(1)
    .padding(.horizontal, 4)
  }
}

struct KeyboardSequenceItem_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let keyboardShortcut = ModelKit.KeyboardShortcut.init(key: "A", modifiers: [.command])

    return KeyboardSequenceItem(title: keyboardShortcut.modifersDisplayValue,
                         subtitle: keyboardShortcut.key)
      .frame(width: 200)
  }
}
