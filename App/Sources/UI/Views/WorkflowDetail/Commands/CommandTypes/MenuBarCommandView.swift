import Bonzai
import HotSwiftUI
import SwiftUI

struct MenuBarCommandView: View {
  private let model: CommandViewModel.Kind.MenuBarModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.MenuBarModel, iconSize: CGSize) {
    self.model = model
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    MenuBarCommandInternalView(metaData, model: model, iconSize: iconSize)
  }
}

private struct MenuBarCommandInternalView: View {
  @EnvironmentObject var openWindow: WindowOpener
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var model: CommandViewModel.Kind.MenuBarModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.MenuBarModel, iconSize: CGSize) {
    _model = Binding<CommandViewModel.Kind.MenuBarModel>(model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(metaData, placeholder: model.placeholder) {
      MenuIconView(size: iconSize.width)
    } content: {
      MenuBarCommandContentView(model)
    } subContent: {
      HStack {
        Spacer()
        Button {
          openWindow.openNewCommandWindow(.editCommand(workflowId: transaction.workflowID, commandId: metaData.id))
        } label: {
          Text("Edit")
            .font(.caption)
        }
      }
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
                .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1),
            )
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(
                  LinearGradient(colors: [
                    Color(nsColor: .systemBlue).opacity(0.7),
                    Color(nsColor: .systemBlue.withSystemEffect(.disabled)).opacity(0.4),
                  ], startPoint: .top, endPoint: .bottom),
                )
                .grayscale(0.4),
            )
            .compositingGroup()
            .shadow(radius: 2, y: 1)
            .font(.caption)
        }

        ForEach(model.tokens) { token in
          switch token {
          case let .menuItem(name):
            HStack(spacing: 0) {
              Text(name)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
              if token != model.tokens.last {
                Text("❯")
                  .padding(.leading, 4)
              }
            }
          case let .menuItems(lhs, rhs):
            HStack(spacing: 0) {
              Text(lhs)
                .bold()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
              Text(" or ")
              Text(rhs)
                .bold()
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
            .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1),
        )
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(
              LinearGradient(colors: [
                Color(nsColor: .controlAccentColor).opacity(0.7),
                Color(nsColor: .controlAccentColor.withSystemEffect(.disabled)).opacity(0.4),
              ], startPoint: .top, endPoint: .bottom),
            )
            .grayscale(0.4),
        )
        .compositingGroup()
        .shadow(radius: 2, y: 1)
        .font(.caption)
      }
    }
  }
}

struct MenuBarCommandView_Previews: PreviewProvider {
  static let command = DesignTime.menuBarCommand
  static var previews: some View {
    MenuBarCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24))
      .designTime()
  }
}
