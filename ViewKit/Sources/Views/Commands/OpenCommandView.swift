import SwiftUI

struct OpenCommandView: View {
  let command: CommandViewModel
  let editAction: (CommandViewModel) -> Void
  let revealAction: (CommandViewModel) -> Void
  let showContextualMenu: Bool

  var body: some View {
    HStack {
      ZStack {
        if case .openUrl(let viewModel) = command.kind {
          IconView(icon: Icon(identifier: viewModel.url.path, path: viewModel.application?.path ?? ""))
        } else if case .openFile(let viewModel) = command.kind {
          IconView(icon: Icon(identifier: viewModel.path, path: viewModel.application?.path ?? ""))
        }
      }.frame(width: 32, height: 32)
      VStack(alignment: .leading, spacing: 0) {
        Text(command.name)
        if showContextualMenu {
          HStack(spacing: 4) {
            Button("Edit", action: { editAction(command) })
              .foregroundColor(Color(.controlAccentColor))
            Text("|").foregroundColor(Color(.secondaryLabelColor))
            Button("Reveal", action: { revealAction(command) })
              .foregroundColor(Color(.controlAccentColor))
          }
          .buttonStyle(LinkButtonStyle())
          .font(Font.caption)
        }
      }
    }
  }
}

struct OpenCommandView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    OpenCommandView(
      command: CommandViewModel(
        name: "",
        kind: .openFile(OpenFileViewModel.empty())),
      editAction: { _ in },
      revealAction: { _ in },
      showContextualMenu: true)
  }
}
