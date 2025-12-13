import Bonzai
import HotSwiftUI
import SwiftUI

struct SystemCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var model: CommandViewModel.Kind.SystemModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.SystemModel,
       iconSize: CGSize)
  {
    _model = Binding<CommandViewModel.Kind.SystemModel>(model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { SystemIconBuilder.icon(model.kind, size: iconSize.width) },
      content: {
        SystemCommandContentView(model: $model) { kind in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case var .systemCommand(systemCommand) = command else { return }

            systemCommand.kind = kind
            command = .systemCommand(systemCommand)
          }
        }
      },
      subContent: {},
    )
    .id(model.id)
    .enableInjection()
  }
}

private struct SystemCommandContentView: View {
  @Binding var model: CommandViewModel.Kind.SystemModel
  let onUpdate: (SystemCommand.Kind) -> Void

  init(model: Binding<CommandViewModel.Kind.SystemModel>, onUpdate: @escaping (SystemCommand.Kind) -> Void) {
    _model = model
    self.onUpdate = onUpdate
  }

  var body: some View {
    HStack(spacing: 8) {
      Menu(content: {
        ForEach(SystemCommand.Kind.allCases) { kind in
          Button(action: {
            model.kind = kind
            onUpdate(kind)
          }, label: {
            HStack {
              Image(systemName: kind.symbol)
              Text(kind.displayValue)
                .font(.subheadline)
            }
          })
        }
      }, label: {
        Image(systemName: model.kind.symbol)
        Text(model.kind.displayValue)
          .font(.subheadline)
          .truncationMode(.middle)
          .allowsTightening(true)
      })
    }
  }
}

struct SystemCommandView_Previews: PreviewProvider {
  static let command = DesignTime.systemCommand
  static var previews: some View {
    SystemCommandView(command.model.meta, model: command.kind,
                      iconSize: .init(width: 24, height: 24))
      .designTime()
  }
}
