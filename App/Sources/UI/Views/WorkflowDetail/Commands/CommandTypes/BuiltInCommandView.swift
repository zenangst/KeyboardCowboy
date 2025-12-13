import Bonzai
import HotSwiftUI
import SwiftUI

struct BuiltInCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.BuiltInModel
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.BuiltInModel, iconSize: CGSize) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData, placeholder: model.placeholder,
      icon: { BuiltinIconBuilder.icon(model.kind, size: iconSize.width) },
      content: {
        BuiltInCommandContentView(model, metaData: metaData)
      }, subContent: {},
    )
    .enableInjection()
  }
}

private struct BuiltInCommandContentView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  @EnvironmentObject var configurationPublisher: ConfigurationPublisher
  @State private var model: CommandViewModel.Kind.BuiltInModel
  private let metaData: CommandViewModel.MetaData

  init(_ model: CommandViewModel.Kind.BuiltInModel, metaData: CommandViewModel.MetaData) {
    self.model = model
    self.metaData = metaData
  }

  var body: some View {
    HStack {
      Menu(content: {
        Button(action: {
          let newKind: BuiltInCommand.Kind = .commandLine(action: .argument(contents: ""))
          performUpdate(newKind)
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          HStack {
            Image(systemName: "command.square.fill")
            Text("Open Command Line").font(.subheadline)
          }
        })

        Button(action: {
          let newKind: BuiltInCommand.Kind = .macro(action: .record)
          performUpdate(newKind)
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          HStack {
            Image(systemName: "record.circle")
            Text("Record Macro").font(.subheadline)
          }
        })

        Button(action: {
          let newKind: BuiltInCommand.Kind = .macro(action: .remove)
          performUpdate(newKind)
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          HStack {
            Image(systemName: "minus.circle.fill")
            Text("Remove Macro").font(.subheadline)
          }
        })

        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(mode: .init(id: model.kind.userModeId, name: model.name, isEnabled: metaData.isEnabled), action: .toggle)
            performUpdate(newKind)
            model.name = newKind.displayValue
            model.kind = newKind
          },
          label: {
            HStack {
              Image(systemName: "togglepower")
              Text("Toggle User Mode").font(.subheadline)
            }
          },
        )
        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(mode: .init(id: model.kind.userModeId, name: model.name, isEnabled: metaData.isEnabled), action: .enable)
            performUpdate(newKind)
            model.name = newKind.displayValue
            model.kind = newKind
          },
          label: {
            HStack {
              Image(systemName: "lightswitch.on")
              Text("Enable User Mode").font(.subheadline)
            }
          },
        )
        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(mode: .init(id: model.kind.userModeId, name: model.name, isEnabled: metaData.isEnabled), action: .disable)
            performUpdate(newKind)
            model.name = newKind.displayValue
            model.kind = newKind
          },
          label: {
            HStack {
              Image(systemName: "lightswitch.off")
              Text("Disable User Mode").font(.subheadline)
            }
          },
        )
      }, label: {
        Text(model.kind.displayValue)
          .font(.subheadline)
      })
      .fixedSize()

      ZenDivider(.vertical)
        .fixedSize()

      switch model.kind {
      case .macro, .commandLine, .repeatLastWorkflow, .windowSwitcher:
        EmptyView()
      case .userMode:
        Menu(content: {
          ForEach(configurationPublisher.data.userModes) { userMode in
            Button(action: {
              let action: BuiltInCommand.Kind.Action
              if case let .userMode(_, resolvedAction) = model.kind {
                action = resolvedAction
                model.kind = .userMode(mode: userMode, action: action)
                performUpdate(model.kind)
              }
            }, label: { Text(userMode.name).font(.subheadline) })
          }
        }, label: {
          Text(configurationPublisher.data.userModes.first(where: { model.kind.id.contains($0.id) })?.name ?? "Pick a User Mode")
            .font(.subheadline)
        })
      }
    }
  }

  private func performUpdate(_ newKind: BuiltInCommand.Kind) {
    updater.modifyCommand(withID: metaData.id, using: transaction) { command in
      guard case let .builtIn(builtInCommand) = command else { return }

      command = .builtIn(BuiltInCommand(kind: newKind,
                                        notification: builtInCommand.notification))
    }
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
        height: 24,
      ),
    )
    .designTime()
  }
}
