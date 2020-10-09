import SwiftUI

struct ApplicationView: View {
  let command: CommandViewModel
  let editAction: (CommandViewModel) -> Void
  let revealAction: (CommandViewModel) -> Void
  let runAction: (CommandViewModel) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      if case .application(let viewModel) = command.kind {
        IconView(identifier: viewModel.bundleIdentifier, path: viewModel.path)
          .frame(width: 32, height: 32)
      }
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button("Edit", action: { editAction(command) })
              .foregroundColor(Color(.controlAccentColor))
            Text("|").foregroundColor(Color(.secondaryLabelColor))
            Button("Reveal", action: { revealAction(command)})
              .foregroundColor(Color(.controlAccentColor))
            Text("|").foregroundColor(Color(.secondaryLabelColor))
            Button("Run command", action: { runAction(command) })
              .foregroundColor(Color(.controlAccentColor))
          }
          .buttonStyle(LinkButtonStyle())
          .font(Font.caption)
        }
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
        kind: .application(ApplicationViewModel.finder())),
      editAction: { _ in },
      revealAction: { _ in },
      runAction: { _ in },
      showContextualMenu: true)
      .frame(maxWidth: 450)
      .environmentObject(UserSelection())
  }
}
