import SwiftUI

struct ScriptCommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel

  var body: some View {
    CommandContainerView(isEnabled: $command.isEnabled, icon: {
      Rectangle()
        .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
        .cornerRadius(8, antialiased: false)
      Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Script Editor.app"))
        .resizable()
        .aspectRatio(1, contentMode: .fill)
        .frame(width: 32)
    }, content: {
      HStack(spacing: 8) {
        Text(command.name)
          .allowsTightening(true)
          .font(.body)
          .bold()
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .truncationMode(.head)
        Spacer()
      }
    }, subContent: {
      HStack {
        if case .script(let kind) = command.kind {
          switch kind {
          case .inline:
            Button("Edit", action: { })
          case .path:
            Button("Open", action: { })
            Button("Reveal", action: { })
          }
        }
      }
      .font(.caption)
    }, onAction: {

    })
    .enableInjection()
  }
}

struct ScriptCommandView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      ScriptCommandView(command: .constant(DesignTime.scriptCommandInline))
        .frame(maxHeight: 80)
      Divider()
      ScriptCommandView(command: .constant(DesignTime.scriptCommandWithPath))
        .frame(maxHeight: 80)
    }
  }
}
