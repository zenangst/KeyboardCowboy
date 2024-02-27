import Bonzai
import Inject
import SwiftUI

struct BuiltInCommandView: View {
  enum Action { 
    case update(BuiltInCommand)
    case commandAction(CommandContainerAction)
  }
  @ObserveInjection var inject
  @EnvironmentObject var configurationPublisher: ConfigurationPublisher
  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.BuiltInModel

  private let iconSize: CGSize
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData, 
       model: CommandViewModel.Kind.BuiltInModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    Group {
      CommandContainerView($metaData, placeholder: model.placheolder) { command in

        switch model.kind {
        case .macro(let macroAction):
          switch macroAction.kind {
          case .record: MacroIconView(.record, size: iconSize.width)
          case .remove: MacroIconView(.remove, size: iconSize.width)
          }
        case .userMode:
          UserModeIconView(size: iconSize.width)
        }

      } content: { _ in
        HStack {
          Menu(content: {
            Button(action: {
              let newKind: BuiltInCommand.Kind = .macro(.record)
              onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
              model.name = newKind.displayValue
              model.kind = newKind
            }, label: {
              Text("Record Macro").font(.subheadline)
            })

            Button(action: {
              let newKind: BuiltInCommand.Kind = .macro(.remove)
              onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
              model.name = newKind.displayValue
              model.kind = newKind
            }, label: {
              Text("Remove Macro").font(.subheadline)
            })

            Button(
              action: {
                let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: true), .toggle)
                onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
                model.name = newKind.displayValue
                model.kind = newKind
              },
              label: {
                Text("Toggle User Mode").font(.subheadline)
              })
            Button(
              action: {
                let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: true), .enable)
                onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
                model.name = newKind.displayValue
                model.kind = newKind
              },
              label: { Text("Enable User Mode").font(.subheadline) })
            Button(
              action: {
                let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: true), .disable)
                onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
                model.name = newKind.displayValue
                model.kind = newKind
              },
              label: { Text("Disable User Mode").font(.subheadline) })
          }, label: {
            Text(model.kind.displayValue)
              .font(.subheadline)
          })
          .fixedSize()

          switch model.kind {
            case .macro:
              EmptyView()
            case .userMode:
              Menu(content: {
                ForEach(configurationPublisher.data.userModes) { userMode in
                  Button(action: {
                    let action: BuiltInCommand.Kind.Action
                    if case .userMode(_, let resolvedAction) = model.kind {
                      action = resolvedAction
                      onAction(.update(.init(id: model.id, kind: .userMode(userMode, action), notification: true)))
                      model.kind = .userMode(userMode, action)
                    }
                  }, label: { Text(userMode.name).font(.subheadline) })
                }
              }, label: {
                Text(configurationPublisher.data.userModes.first(where: { model.kind.id.contains($0.id) })?.name ?? "Pick a User Mode")
                  .font(.subheadline)
              })
          }

        }
          .menuStyle(.regular)
      } subContent: { _ in } onAction: {
        onAction(.commandAction($0))
      }

    }
    .enableInjection()
  }
}

struct BuiltInCommandView_Previews: PreviewProvider {
  static let command = DesignTime.builtInCommand
  static var previews: some View {
    BuiltInCommandView(
      command.model.meta,
      model: command.kind,
      iconSize: .init(
        width: 24,
        height: 24
      )
    ) { _ in }
      .designTime()
      .frame(maxHeight: 80)
  }
}

