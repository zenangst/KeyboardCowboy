import Bonzai
import HotSwiftUI
import SwiftUI

struct WindowFocusCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var model: CommandViewModel.Kind.WindowFocusModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.WindowFocusModel,
       iconSize: CGSize) {
    _model = Binding<CommandViewModel.Kind.WindowFocusModel>(model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { WindowFocusIconBuilder.icon(model.kind, size: iconSize.width) },
      content: {
        ContentView(model: $model) { kind in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case var .windowFocus(focusCommand) = command else { return }

            focusCommand.kind = kind
            command = .windowFocus(focusCommand)
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
  @Binding var model: CommandViewModel.Kind.WindowFocusModel
  let onUpdate: (WindowFocusCommand.Kind) -> Void

  init(model: Binding<CommandViewModel.Kind.WindowFocusModel>, onUpdate: @escaping (WindowFocusCommand.Kind) -> Void) {
    _model = model
    self.onUpdate = onUpdate
  }

  var body: some View {
    HStack(spacing: 8) {
      Menu(content: {
        ForEach(WindowFocusCommand.Kind.allCases) { kind in
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
