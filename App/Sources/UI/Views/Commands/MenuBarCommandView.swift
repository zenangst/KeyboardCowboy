import SwiftUI

struct MenuBarCommandView: View {
  enum Action {
    case editCommand(DetailViewModel.CommandViewModel)
    case commandAction(CommandContainerAction)
  }
  @Environment(\.openWindow) private var openWindow
  @Binding private var command: DetailViewModel.CommandViewModel
  @Binding private var tokens: [MenuBarCommand.Token]
  private let onAction: (Action) -> Void

  init(_ command: Binding<DetailViewModel.CommandViewModel>,
       tokens: Binding<[MenuBarCommand.Token]>,
       onAction: @escaping (Action) -> Void) {
    _command = command
    _tokens = tokens
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($command) { _ in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        Image(nsImage: NSWorkspace.shared.icon(forFile:"/System/Library/PreferencePanes/Appearance.prefPane"))
          .resizable()
          .aspectRatio(1, contentMode: .fill)
          .frame(width: 32)
      }
    } content: { _ in
      VStack(alignment: .leading, spacing: 4) {
        ForEach(tokens) { token in
          switch token {
          case .menuItem(let name):
            Text(name)
          case .menuItems(let lhs, let rhs):
            HStack(spacing: 0) {
              Text(lhs).bold()
              Text(" or ")
              Text(rhs).bold()
            }
          }
        }
        .padding(.horizontal, 4)
        .font(.caption)
      }
    } subContent: { _ in
      Button {
        onAction(.editCommand(command))
      } label: {
        Text("Edit")
          .font(.caption)
      }
      .buttonStyle(.gradientStyle(config: .init(nsColor: .systemCyan, grayscaleEffect: true)))

    } onAction: { action in
      onAction(.commandAction(action))
    }
  }
}

struct MenuBarCommandView_Previews: PreviewProvider {
  static let command: DetailViewModel.CommandViewModel = .init(
    id: UUID().uuidString,
    name: "Hello, world!",
    kind: .menuBar(tokens: []),
    isEnabled: true,
    notify: false)
  static var previews: some View {
    MenuBarCommandView(.constant(command),
                       tokens: .constant([
                        .menuItem(name: "View"),
                        .menuItem(name: "Navigators"),
                        .menuItems(name: "Show Navigator", fallbackName: "Hide Navigator")
                       ])) { _ in }
  }
}
