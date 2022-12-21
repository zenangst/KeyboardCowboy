import SwiftUI

struct ShortcutCommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel
  
  var body: some View {
    CommandContainerView(isEnabled: $command.isEnabled, icon: {
      Rectangle()
        .fill(Color(nsColor: .controlAccentColor).opacity(0.375))
        .cornerRadius(8, antialiased: false)
      Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
    }, content: {
      Text(command.name)
    }, subContent: {
      Button("Open Shortcuts", action: {})
    }, onAction: { })
      .enableInjection()
  }
}

struct ShortcutCommandView_Previews: PreviewProvider {
  static var previews: some View {
    ShortcutCommandView(command: .constant(DesignTime.shortcutCommand))
  }
}
