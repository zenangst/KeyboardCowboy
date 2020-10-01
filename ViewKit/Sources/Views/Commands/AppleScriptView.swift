import SwiftUI

struct AppleScriptView: View {
  let command: CommandViewModel

  var body: some View {
    HStack {
      ZStack {
        IconView(
          identifier: "script-editor-file",
          path: "/System/Applications/Utilities/Script Editor.app/Contents/Resources/script-editor-dummy.scptd")
        PlayArrowView()
      }
        .frame(width: 32, height: 32)
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        HStack(spacing: 4) {
          Button("Change", action: {})
            .foregroundColor(Color(.controlAccentColor))
          Text("|").foregroundColor(Color(.secondaryLabelColor))
          Button("Reveal", action: {})
            .foregroundColor(Color(.controlAccentColor))
          Text("|").foregroundColor(Color(.secondaryLabelColor))
          Button("Run Apple script", action: {})
            .foregroundColor(Color(.controlAccentColor))
        }.buttonStyle(LinkButtonStyle())
        .font(Font.caption)
      }
    }
  }
}

struct AppleScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    AppleScriptView(command: CommandViewModel(id: UUID().uuidString, name: "Run script", kind: .appleScript))
  }
}
