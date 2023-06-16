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
          .frame(width: 32, height: 32)
        Image(nsImage: NSWorkspace.shared.icon(forFile:"/System/Library/PreferencePanes/Appearance.prefPane"))
          .resizable()
          .aspectRatio(1, contentMode: .fit)
          .frame(width: 28, height: 28)
      }
    } content: { _ in
      ScrollView {
        HStack(spacing: 4) {
          ForEach(tokens) { token in
            switch token {
            case .menuItem(let name):
              HStack(spacing: 0) {
                Text(name)
                  .lineLimit(1)
                  .fixedSize(horizontal: true, vertical: true)
                if token != tokens.last {
                  Text("❯")
                    .padding(.leading, 4)
                }
              }
            case .menuItems(let lhs, let rhs):
              HStack(spacing: 0) {
                Text(lhs).bold()
                  .lineLimit(1)
                  .fixedSize(horizontal: true, vertical: true)
                Text(" or ")
                Text(rhs).bold()
                  .lineLimit(1)
                  .fixedSize(horizontal: true, vertical: true)
                if token != tokens.last {
                  Text("❯")
                    .padding(.leading, 4)
                }
              }
            }
          }
          .padding(4)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1)
          )
          .background(
            RoundedRectangle(cornerRadius: 4)
              .fill(
                LinearGradient(colors: [
                  Color(nsColor: .windowBackgroundColor),
                  Color(nsColor: .gridColor),
                ], startPoint: .top, endPoint: .bottom)
              )
          )
          .shadow(radius: 3)
          .font(.caption)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
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
                        .menuItem(name: "Editor"),
                        .menuItem(name: "Canvas"),
//                        .menuItems(name: "Show Navigator", fallbackName: "Hide Navigator")
                       ])) { _ in }
      .frame(maxHeight: 80)
  }
}
