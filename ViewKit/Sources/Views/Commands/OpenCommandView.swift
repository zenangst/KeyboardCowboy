import SwiftUI

struct OpenCommandView: View {
  let command: CommandViewModel

  var body: some View {
    HStack {
      ZStack {
        if case .openUrl(let url, let application) = command.kind {
          IconView(identifier: url, path: application)
        } else if case .openFile(let path, let application) = command.kind {
          IconView(identifier: path, path: application)
        }
      }.frame(width: 32, height: 32)
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        HStack(spacing: 4) {
          Button("Change", action: {})
            .foregroundColor(Color(.controlAccentColor))
          Text("|").foregroundColor(Color(.secondaryLabelColor))
          Button("Reveal", action: {})
            .foregroundColor(Color(.controlAccentColor))
        }
        .buttonStyle(LinkButtonStyle())
        .font(Font.caption)
      }
    }
  }
}

struct OpenCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    OpenCommandView(command: CommandViewModel(name: "", kind: .openFile(path: "", application: "")))
  }
}
