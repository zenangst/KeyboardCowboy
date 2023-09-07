import SwiftUI

struct MenuBarCommandView: View {
  enum Action {
    case editCommand(CommandViewModel.Kind.MenuBarModel)
    case commandAction(CommandContainerAction)
  }
  @Environment(\.openWindow) private var openWindow
  @State var metaData: CommandViewModel.MetaData
  @Binding var model: CommandViewModel.Kind.MenuBarModel
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.MenuBarModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = Binding<CommandViewModel.Kind.MenuBarModel>(model)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData) { _ in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
          .frame(width: 32, height: 32)
        IconView(icon: .init(bundleIdentifier: "/System/Library/PreferencePanes/Appearance.prefPane",
                             path: "/System/Library/PreferencePanes/Appearance.prefPane"),
                 size: .init(width: 28, height: 28))
      }
    } content: { _ in
      ScrollView(.horizontal) {
        HStack(spacing: 4) {
          ForEach(model.tokens) { token in
            switch token {
            case .menuItem(let name):
              HStack(spacing: 0) {
                Text(name)
                  .lineLimit(1)
                  .fixedSize(horizontal: true, vertical: true)
                if token != model.tokens.last {
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
                if token != model.tokens.last {
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
      .scrollIndicators(.hidden)
    } subContent: { _ in
      Button {
        onAction(.editCommand(model))
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
  static let command = DesignTime.menuBarCommand
  static var previews: some View {
    MenuBarCommandView(command.model.meta, model: command.kind) { _ in }
      .designTime()
      .frame(maxHeight: 80)
  }
}
