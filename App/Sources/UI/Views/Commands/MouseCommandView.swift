import Bonzai
import Inject
import SwiftUI

struct MouseCommandView: View {
  enum Action {
    case update(MouseCommand.Kind)
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.MouseModel
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.MouseModel,
       onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      $metaData,
      icon: { command in
        switch command.icon.wrappedValue {
        case .some(let icon):
          IconView(icon: icon, size: .init(width: 32, height: 32))
        case .none:
          EmptyView()
        }
      },
      content: { _ in
        Menu(content: {
          ForEach(MouseCommand.Kind.allCases) { kind in
            Button(action: {
              model.kind = kind
            }, label: {
              Text(kind.displayValue)
            })
          }
        }, label: {
          Text(model.kind.displayValue)
        })
        .onChange(of: model.kind, perform: { newValue in
          onAction(.update(newValue))
        })
        .menuStyle(.regular)
      },
      subContent: { _ in },
      onAction: { action in
        onAction(.commandAction(action))
      })
      .enableInjection()
  }
}
