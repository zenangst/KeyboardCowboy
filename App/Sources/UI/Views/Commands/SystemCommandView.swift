import Bonzai
import Inject
import SwiftUI

struct SystemCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updateKind(newKind: SystemCommand.Kind)
    case commandAction(CommandContainerAction)
  }
  @State var metaData: CommandViewModel.MetaData
  @Binding var model: CommandViewModel.Kind.SystemModel
  let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.SystemModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = Binding<CommandViewModel.Kind.SystemModel>(model)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, icon: { command in
      ZStack {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.375))
          .cornerRadius(8, antialiased: false)
        IconView(icon: Icon(bundleIdentifier: model.kind.iconPath,
                            path: model.kind.iconPath), size: .init(width: 32, height: 32))
          .allowsHitTesting(false)
      }
    }, content: { command in
      HStack(spacing: 8) {
        Menu(content: {
          ForEach(SystemCommand.Kind.allCases) { kind in
            Button(action: {
              model.kind = kind
              onAction(.updateKind(newKind: kind))
            }, label: {
              Image(systemName: kind.symbol)
              Text(kind.displayValue)
                .font(.subheadline)
            })
          }
        }, label: {
          HStack(spacing: 4) {
            Image(systemName: model.kind.symbol)
            Text(model.kind.displayValue)
              .font(.subheadline)
              .truncationMode(.middle)
              .allowsTightening(true)
          }
          .padding(4)
        })
        .menuStyle(.regular)
      }
    }, subContent: { _ in },
    onAction: { onAction(.commandAction($0)) })
    .id(model.id)
    .enableInjection()
  }
}


struct SystemCommandView_Previews: PreviewProvider {
  static let command = DesignTime.systemCommand
  static var previews: some View {
    SystemCommandView(command.model.meta, model: command.kind) { _ in }
      .designTime()
  }
}
