import SwiftUI

struct ShortcutCommandView: View {
  enum Action {
    case updateName(newName: String)
    case openShortcuts
    case commandAction(CommandContainerAction)
  }

  @State private var name: String
  @State var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: DetailViewModel.CommandViewModel,
       onAction: @escaping (Action) -> Void) {
    _command = .init(initialValue: command)
    _name = .init(initialValue: command.name)
    self.onAction = onAction
  }
  
  var body: some View {
    CommandContainerView(command, icon: {
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
      }
    }, content: {
      TextField("", text: $name)
        .textFieldStyle(AppTextFieldStyle())
        .onChange(of: name, perform: {
          onAction(.updateName(newName: $0))
        })
    }, subContent: {
      Button("Open Shortcuts", action: { onAction(.openShortcuts) })
    }, onAction: { onAction(.commandAction($0)) })
  }
}

struct ShortcutCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ShortcutCommandView(DesignTime.shortcutCommand, onAction: { _ in})
  }
}
