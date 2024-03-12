import Bonzai
import Inject
import SwiftUI

struct BuiltInCommandView: View {
  enum Action { 
    case update(BuiltInCommand)
    case commandAction(CommandContainerAction)
  }

  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.BuiltInModel
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
    CommandContainerView(metaData, placeholder: model.placheolder) { command in
      BuiltInIconView(model.kind, iconSize: iconSize)
    } content: { _ in
      BuiltInCommandContentView(model, onAction: onAction)
    } subContent: { _ in } onAction: {
      onAction(.commandAction($0))
    }
  }
}


private struct BuiltInIconView: View {
  let kind: BuiltInCommand.Kind
  let iconSize: CGSize

  init(_ kind: BuiltInCommand.Kind, iconSize: CGSize) {
    self.kind = kind
    self.iconSize = iconSize
  }

  var body: some View {
    switch kind {
    case .macro(let macroAction):
      switch macroAction.kind {
      case .record: MacroIconView(.record, size: iconSize.width)
      case .remove: MacroIconView(.remove, size: iconSize.width)
      }
    case .userMode:
      UserModeIconView(size: iconSize.width)
    }
  }
}

private struct BuiltInCommandContentView: View {
  @EnvironmentObject var configurationPublisher: ConfigurationPublisher
  @State private var model: CommandViewModel.Kind.BuiltInModel
  private let onAction: (BuiltInCommandView.Action) -> Void

  init(_ model: CommandViewModel.Kind.BuiltInModel, onAction: @escaping (BuiltInCommandView.Action) -> Void) {
    self.model = model
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      Menu(content: {
        Button(action: {
          let newKind: BuiltInCommand.Kind = .macro(.record)
          onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          Image(systemName: "record.circle")
          Text("Record Macro").font(.subheadline)
        })

        Button(action: {
          let newKind: BuiltInCommand.Kind = .macro(.remove)
          onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          Image(systemName: "minus.circle.fill")
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
            Image(systemName: "togglepower")
            Text("Toggle User Mode").font(.subheadline)
          })
        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: true), .enable)
            onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
            model.name = newKind.displayValue
            model.kind = newKind
          },
          label: {
            Image(systemName: "lightswitch.on")
            Text("Enable User Mode").font(.subheadline)
          })
        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: true), .disable)
            onAction(.update(.init(id: model.id, kind: newKind, notification: true)))
            model.name = newKind.displayValue
            model.kind = newKind
          },
          label: {
            Image(systemName: "lightswitch.off")
            Text("Disable User Mode").font(.subheadline)
          })
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

