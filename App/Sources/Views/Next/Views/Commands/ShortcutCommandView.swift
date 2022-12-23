import SwiftUI

struct ShortcutCommandView: View {
  enum Action {
    case openShortcuts
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    self.onAction = onAction
  }
  
  var body: some View {
    CommandContainerView(isEnabled: $command.isEnabled, icon: {
      Rectangle()
        .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
        .cornerRadius(8, antialiased: false)
      Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
    }, content: {
      Text(command.name)
    }, subContent: {
      Button("Open Shortcuts", action: { onAction(.openShortcuts) })
    }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct ShortcutCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ShortcutCommandView(.constant(DesignTime.shortcutCommand), onAction: { _ in})
  }
}
