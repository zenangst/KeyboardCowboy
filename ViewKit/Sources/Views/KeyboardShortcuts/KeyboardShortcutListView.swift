import SwiftUI

struct KeyboardShortcutListView: View {
  let combinations: [KeyboardShortcutViewModel]

  var body: some View {
    VStack(spacing: 0) {
      ForEach(combinations) { combination in
        HStack {
          Text("1.").padding(.horizontal, 10)
          KeyboardShortcutView(combination: combination)
          HStack(spacing: 4) {
            RoundFillButton(title: "+", color: Color(.systemGreen))
            RoundFillButton(title: "-", color: Color(.systemRed))
          }
          Text("≣")
            .font(.title)
            .foregroundColor(Color(.secondaryLabelColor))
            .padding(8)
            .offset(x: 0, y: -2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .cornerRadius(8.0)
        .tag(combination)
        Divider()
      }

      HStack(spacing: 2) {
        Spacer()
        RoundFillButton(title: "+", color: Color(.systemGreen))
        Button("Add keyboard shortcut", action: {})
          .buttonStyle(LinkButtonStyle())
      }.padding([.top, .trailing], 10)
    }
    .padding(.bottom, 10)
  }
}

// MARK: - Previews

struct KeyboardShortcutListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutListView(combinations: ModelFactory().keyboardShortcuts())
  }
}
