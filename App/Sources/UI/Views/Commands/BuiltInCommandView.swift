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

  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.BuiltInModel, onAction: @escaping (Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.onAction = onAction
  }

  var body: some View {
    Group {
      CommandContainerView($metaData) { command in
        switch command.icon.wrappedValue {
        case .some(let icon):
          Color.accentColor.opacity(0.375)
            .cornerRadius(8, antialiased: false)
            .frame(width: 32, height: 32)
            .overlay(content: {
              IconView(icon: icon, size: .init(width: 24, height: 24))
                .fixedSize()
            })
            .allowsHitTesting(false)
        case .none:
          EmptyView()
        }
      } content: { _ in
        HStack {
          Menu(content: {
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
            Text(model.name)
              .font(.subheadline)
          })
          .fixedSize()
          Menu(content: {
            ForEach(configurationPublisher.data.userModes) { userMode in
              Button(action: {
                let action: BuiltInCommand.Kind.Action
                switch model.kind {
                   case .userMode(_, let resolvedAction):
                  action = resolvedAction
                }
                onAction(.update(.init(id: model.id, kind: .userMode(userMode, action), notification: true)))
                model.kind = .userMode(userMode, action)
              }, label: { Text(userMode.name).font(.subheadline) })
            }
          }, label: {
            Text(configurationPublisher.data.userModes.first(where: { model.kind.id.contains($0.id) })?.name ?? "Pick a User Mode")
              .font(.subheadline)
          })
        }
          .menuStyle(.regular)
      } subContent: { _ in

      } onAction: {
        onAction(.commandAction($0))
      }

    }
    .enableInjection()
  }
}

struct BuiltInCommandView_Previews: PreviewProvider {
  static let command = DesignTime.builtInCommand
  static var previews: some View {
    BuiltInCommandView(command.model.meta, model: command.kind) { _ in }
      .designTime()
      .frame(maxHeight: 80)
  }
}

