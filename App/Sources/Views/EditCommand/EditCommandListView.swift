import SwiftUI

struct EditCommandListView: View {
  @ObserveInjection var inject
  @Binding var selection: Command?
  @Binding var command: Command
  private let imageSize = CGSize(width: 32, height: 32)
  let commands: [Command]

  var body: some View {
    List(selection: Binding<Command?>(get: { selection }, set: { newCommand in
      if let newCommand = newCommand {
        command = newCommand
      }
      selection = newCommand
    }) ) {
      ForEach(commands, id: \.self) { command in
        HStack {
          switch command {
          case .application:
            FeatureIcon(color: .red, size: imageSize) {
              AppSymbol()
                .fixedSize(horizontal: true, vertical: true)
                .padding()
            }
          case .script(let kind):
            switch kind {
            case .appleScript:
              FeatureIcon(color: .orange, size: imageSize, {
                ScriptSymbol(cornerRadius: 3,
                             foreground: .yellow,
                             background: .white.opacity(0.7),
                             borderColor: .white)
              }).redacted(reason: .placeholder)
            case .shell:
              FeatureIcon(color: .yellow, size: imageSize, {
                ScriptSymbol(cornerRadius: 3,
                             foreground: .yellow,
                             background: .white.opacity(0.7),
                             borderColor: .white)
              }).redacted(reason: .placeholder)
            }
          case .shortcut:
            FeatureIcon(color: Color(.systemPurple), size: imageSize, {
              CommandSymbolIcon(background: .white.opacity(0.85), textColor: Color(.systemPurple))
            }).redacted(reason: .placeholder)
          case .keyboard:
            FeatureIcon(color: .green, size: imageSize, {
              CommandSymbolIcon(background: .white.opacity(0.85), textColor: Color.green)
            }).redacted(reason: .placeholder)
          case .open(let kind):
            if !kind.isUrl {
              FeatureIcon(color: .blue, size: imageSize, {
                FolderSymbol(cornerRadius: 0.06, textColor: .blue)
              }).redacted(reason: .placeholder)
            } else {
              FeatureIcon(color: .purple, size: imageSize, {
                URLSymbol()
              }).redacted(reason: .placeholder)
            }
          case .type:
            FeatureIcon(color: .pink, size: imageSize, {
              TypingSymbol(foreground: Color.pink)
            }).redacted(reason: .placeholder)
          case .builtIn:
            FeatureIcon(color: .gray, size: imageSize, {
              Image(systemName: "tornado")
                .foregroundColor(Color.white)
            }).redacted(reason: .placeholder)
          }
          Text(command.name)
        }
        .tag(command.id)
        .frame(height: 36)
      }
    }
  }
}

struct EditCommandListView_Previews: PreviewProvider {
  static let command = Command.empty(.application)
  static var commands = ModelFactory().commands(id: command.id)
  static var previews: some View {
    EditCommandListView(
      selection: .constant(command),
      command: .constant(command),
      commands: commands)
  }
}
