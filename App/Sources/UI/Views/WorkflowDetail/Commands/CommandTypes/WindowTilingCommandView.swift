import Bonzai
import HotSwiftUI
import SwiftUI

struct WindowTilingCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var model: CommandViewModel.Kind.WindowTilingModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.WindowTilingModel,
       iconSize: CGSize) {
    _model = Binding<CommandViewModel.Kind.WindowTilingModel>(model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { WindowTilingIconBuilder.icon(model.kind, size: iconSize.width) },
      content: {
        ContentView(model: $model) { kind in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case var .windowTiling(focusCommand) = command else { return }

            focusCommand.kind = kind
            command = .windowTiling(focusCommand)
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
  @Binding var model: CommandViewModel.Kind.WindowTilingModel
  let onUpdate: (WindowTiling) -> Void

  init(model: Binding<CommandViewModel.Kind.WindowTilingModel>, onUpdate: @escaping (WindowTiling) -> Void) {
    _model = model
    self.onUpdate = onUpdate
  }

  var body: some View {
    HStack(spacing: 8) {
      Menu(content: {
        ForEach(WindowTiling.allCases) { kind in
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
