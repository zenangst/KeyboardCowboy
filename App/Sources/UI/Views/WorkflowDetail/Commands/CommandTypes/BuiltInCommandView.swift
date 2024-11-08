import Bonzai
import Inject
import SwiftUI

struct BuiltInCommandView: View {
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
    CommandContainerView(metaData, placeholder: model.placeholder,
                         icon: { _ in
      BuiltinIconBuilder.icon(model.kind, size: iconSize.width)
    }, content: { _ in
      BuiltInCommandContentView(model, metaData: metaData)
        .roundedContainer(4, padding: 4, margin: 0)
    }, subContent: { metaData in
      ZenCheckbox("Notify", style: .small, isOn: Binding(get: {
        if case .bezel = metaData.notification.wrappedValue { return true } else { return false }
      }, set: { newValue in
        metaData.notification.wrappedValue = newValue ? .bezel : nil
        updater.modifyCommand(withID: metaData.id, using: transaction) { command in
          command.notification = newValue ? .bezel : nil
        }
      })) { value in
        updater.modifyCommand(withID: metaData.id, using: transaction) { command in
          command.notification = value ? .bezel : nil
        }
      }
      .offset(x: 1)
    })
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
          let newKind: BuiltInCommand.Kind = .commandLine(.argument(contents: ""))
          performUpdate(newKind)
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          Image(systemName: "command.square.fill")
          Text("Open Command Line").font(.subheadline)
        })

        Button(action: {
          let newKind: BuiltInCommand.Kind = .macro(.record)
          performUpdate(newKind)
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          Image(systemName: "record.circle")
          Text("Record Macro").font(.subheadline)
        })

        Button(action: {
          let newKind: BuiltInCommand.Kind = .macro(.remove)
          performUpdate(newKind)
          model.name = newKind.displayValue
          model.kind = newKind
        }, label: {
          Image(systemName: "minus.circle.fill")
          Text("Remove Macro").font(.subheadline)
        })

        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: metaData.isEnabled), .toggle)
            performUpdate(newKind)
            model.name = newKind.displayValue
            model.kind = newKind
          },
          label: {
            Image(systemName: "togglepower")
            Text("Toggle User Mode").font(.subheadline)
          })
        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: metaData.isEnabled), .enable)
            performUpdate(newKind)
            model.name = newKind.displayValue
            model.kind = newKind
          },
          label: {
            Image(systemName: "lightswitch.on")
            Text("Enable User Mode").font(.subheadline)
          })
        Button(
          action: {
            let newKind: BuiltInCommand.Kind = .userMode(.init(id: model.kind.userModeId, name: model.name, isEnabled: metaData.isEnabled), .disable)
            performUpdate(newKind)
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

      ZenDivider(.vertical)
        .fixedSize()

      switch model.kind {
      case .macro, .commandLine, .repeatLastWorkflow:
        EmptyView()
      case .userMode:
        Menu(content: {
          ForEach(configurationPublisher.data.userModes) { userMode in
            Button(action: {
              let action: BuiltInCommand.Kind.Action
              if case .userMode(_, let resolvedAction) = model.kind {
                action = resolvedAction
                model.kind = .userMode(userMode, action)
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
    .menuStyle(.regular)
  }

  private func performUpdate(_ newKind: BuiltInCommand.Kind) {
    updater.modifyCommand(withID: metaData.id, using: transaction) { command in
      guard case .builtIn(let builtInCommand) = command else { return }
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
        height: 24
      )
    )
    .designTime()
  }
}

