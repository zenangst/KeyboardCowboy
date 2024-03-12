import Bonzai
import Inject
import SwiftUI

struct MenuBarCommandView: View {
  enum Action {
    case editCommand(CommandViewModel.Kind.MenuBarModel)
    case commandAction(CommandContainerAction)
  }

  private let model: CommandViewModel.Kind.MenuBarModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize
  private let onAction: (Action) -> Void


  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.MenuBarModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    self.model = model
    self.metaData = metaData
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    MenuBarCommandInternalView(metaData, model: model, iconSize: iconSize, onAction: onAction)
  }
}

struct MenuBarCommandInternalView: View {
  @State var metaData: CommandViewModel.MetaData
  @Binding var model: CommandViewModel.Kind.MenuBarModel
  private let iconSize: CGSize
  private let onAction: (MenuBarCommandView.Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.MenuBarModel,
       iconSize: CGSize,
       onAction: @escaping (MenuBarCommandView.Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = Binding<CommandViewModel.Kind.MenuBarModel>(model)
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, placeholder: model.placeholder) { _ in
      MenuIconView(size: iconSize.width)
    } content: { _ in
      MenuBarCommandContentView(model)
    } subContent: { _ in
      Button { onAction(.editCommand(model)) } label: { 
        Text("Edit")
          .font(.caption)
      }
      .buttonStyle(.zen(.init(color: .systemCyan, grayscaleEffect: .constant(true))))
    } onAction: { action in
      onAction(.commandAction(action))
    }
  }
}

private struct MenuBarCommandContentView: View {
  private let model: CommandViewModel.Kind.MenuBarModel

  init(_ model: CommandViewModel.Kind.MenuBarModel) {
    self.model = model
  }

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 4) {
        if let application = model.application {
          Text(application.displayName)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
            .padding(4)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1)
            )
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(
                  LinearGradient(colors: [
                    Color(nsColor: .systemBlue).opacity(0.7),
                    Color(nsColor: .systemBlue.withSystemEffect(.disabled)).opacity(0.4),
                  ], startPoint: .top, endPoint: .bottom)
                )
                .grayscale(0.4)
            )
            .compositingGroup()
            .shadow(radius: 2, y: 1)
            .font(.caption)
        }

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
                Color(nsColor: .controlAccentColor).opacity(0.7),
                Color(nsColor: .controlAccentColor.withSystemEffect(.disabled)).opacity(0.4),
              ], startPoint: .top, endPoint: .bottom)
            )
            .grayscale(0.4)
        )
        .compositingGroup()
        .shadow(radius: 2, y: 1)
        .font(.caption)
      }
      .padding(.horizontal, 2)
    }
  }
}

struct MenuBarCommandView_Previews: PreviewProvider {
  static let command = DesignTime.menuBarCommand
  static var previews: some View {
    MenuBarCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
  }
}
