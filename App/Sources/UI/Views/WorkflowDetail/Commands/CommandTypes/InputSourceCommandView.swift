import Bonzai
import Inject
import SwiftUI

struct InputSourceCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var model: CommandViewModel.Kind.InputSourceModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.InputSourceModel,
       iconSize: CGSize)
  {
    _model = Binding<CommandViewModel.Kind.InputSourceModel>(model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { InputSourceIcon(size: iconSize.width) },
      content: {
        ContentView(model: $model) { id, name in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            let kind: KeyboardCommand.Kind = .inputSource(
              command: KeyboardCommand.InputSourceCommand(
                id: command.id,
                inputSourceId: id,
                name: name,
              ),
            )
            command = Command.keyboard(.init(name: command.name, kind: kind))
          }
        }
      },
      subContent: {},
    )
    .id(model.id)
    .enableInjection()
  }
}

private struct ContentView: View {
  @EnvironmentObject var store: InputSourceStore
  @Binding var model: CommandViewModel.Kind.InputSourceModel
  let onUpdate: (_ id: String, _ name: String) -> Void

  init(model: Binding<CommandViewModel.Kind.InputSourceModel>, onUpdate: @escaping (_ id: String, _ name: String) -> Void) {
    _model = model
    self.onUpdate = onUpdate
  }

  var body: some View {
    HStack(spacing: 8) {
      Menu(content: {
        ForEach(store.inputSources, id: \.id) { inputSource in
          Button(action: { onUpdate(inputSource.id, inputSource.localizedName ?? inputSource.id) },
                 label: { Text(inputSource.localizedName ?? inputSource.id) })
        }
      }, label: {
        Text(model.name)
          .font(.subheadline)
          .truncationMode(.middle)
          .allowsTightening(true)
      })
    }
  }
}
