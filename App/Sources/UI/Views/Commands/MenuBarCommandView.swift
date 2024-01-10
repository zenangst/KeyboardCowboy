import Bonzai
import Inject
import SwiftUI

struct MenuBarCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case editCommand(CommandViewModel.Kind.MenuBarModel)
    case commandAction(CommandContainerAction)
  }
  @Environment(\.openWindow) private var openWindow
  @State var metaData: CommandViewModel.MetaData
  @Binding var model: CommandViewModel.Kind.MenuBarModel
  private let iconSize: CGSize
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.MenuBarModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = Binding<CommandViewModel.Kind.MenuBarModel>(model)
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, placeholder: model.placeholder) { _ in
      IconView(icon: .init(bundleIdentifier: "/System/Library/PreferencePanes/Appearance.prefPane",
                           path: "/System/Library/PreferencePanes/Appearance.prefPane"),
               size: iconSize)
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
                  Color(nsColor: .gridColor).opacity(0.5),
                ], startPoint: .top, endPoint: .bottom)
              )
          )
          .compositingGroup()
          .shadow(radius: 2, y: 1)
          .font(.caption)
        }
        .padding(.horizontal, 2)
      }
      .scrollIndicators(.hidden)
    } subContent: { _ in
      Button {
        onAction(.editCommand(model))
      } label: {
        Text("Edit")
          .font(.caption)
      }
      .buttonStyle(.zen(.init(color: .systemCyan, grayscaleEffect: .constant(true))))
    } onAction: { action in
      onAction(.commandAction(action))
    }
    .enableInjection()
  }
}

struct MenuBarCommandView_Previews: PreviewProvider {
  static let command = DesignTime.menuBarCommand
  static var previews: some View {
    MenuBarCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
      .frame(maxHeight: 80)
  }
}
