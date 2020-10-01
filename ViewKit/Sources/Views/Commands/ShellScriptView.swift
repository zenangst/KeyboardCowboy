import SwiftUI

struct ShellScriptView: View {
  let command: CommandViewModel

  var body: some View {
    HStack {
      ZStack {
        IconView(identifier: "shell-script-file", path: "/System/Applications/Utilities/Terminal.app")
          .frame(width: 32, height: 32)
        PlayArrowView()
      }
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

struct ShellScriptView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    ShellScriptView(command: CommandViewModel(id: UUID().uuidString,
                                              name: "Run script",
                                              kind: .shellScript))
  }
}
