import SwiftUI

struct ApplicationView: View {
  let command: CommandViewModel

  init(command: CommandViewModel) {
    self.command = command
  }

  var body: some View {
    HStack {
      if case .application(let path, let identifier) = command.kind {
        IconView(identifier: identifier, path: path)
          .frame(width: 32, height: 32)
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
          Button("Run command", action: {})
            .foregroundColor(Color(.controlAccentColor))
        }
        .buttonStyle(LinkButtonStyle())
        .font(Font.caption)
      }
      Spacer()
    }
    .alignmentGuide(.leading, computeValue: { dimension in
      dimension[.leading]
    })
  }
}

struct ApplicationView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    ApplicationView(
      command: CommandViewModel(
        id: UUID().uuidString,
        name: "Finder",
        kind: .application(path: "/System/Library/CoreServices/Finder.app",
                           bundleIdentifier: "com.apple.finder")))
      .frame(maxWidth: 450)
      .environmentObject(UserSelection())
  }
}
