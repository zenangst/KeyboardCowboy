import Apps
import Bonzai
import Inject
import SwiftUI

struct ApplicationCommandView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @ObserveInjection var inject
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.ApplicationModel
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.ApplicationModel, iconSize: CGSize) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placeholder,
      icon: { _ in
        ApplicationCommandImageView(metaData, iconSize: iconSize)
      },
      content: { _ in 
        ApplicationCommandInternalView(metaData, model: model, iconSize: iconSize)
        .roundedContainer(4, padding: 4, margin: 0)
      },
      subContent: {
        Menu {
          Button(action: {
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              command.notification = .none
            }
          }, label: { Text("None") })
          ForEach(Command.Notification.regularCases) { notification in
            Button(action: {
              updater.modifyCommand(withID: metaData.id, using: transaction) { command in
                command.notification = notification
              }
            }, label: { Text(notification.displayValue) })
          }
        } label: {
          switch metaData.notification {
          case .bezel:        Text("Bezel").font(.caption)
          case .capsule:      Text("Capsule").font(.caption)
          case .commandPanel: Text("Command Panel").font(.caption)
          case .none:         Text("None").font(.caption)
          }
        }
        .menuStyle(.zen(.init(color: .systemGray, padding: .medium)))
        .fixedSize()
      }
    )
    .enableInjection()
  }
}

private struct ApplicationCommandInternalView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject private var applicationStore: ApplicationStore
  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.ApplicationModel
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.ApplicationModel, iconSize: CGSize) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.iconSize = iconSize
  }

  var body: some View {
    HStack(spacing: 4) {
      Menu(content: {
        Button(action: {
          model.action = "Open"
          updateAction(.open)
        }, label: {
          HStack {
            Image(systemName: "power")
            Text("Open")
              .font(.subheadline)
          }
        })

        Button(action: {
          model.action = "Close"
          updateAction(.close)
        }, label: {
          HStack {
            Image(systemName: "poweroff")
            Text("Close")
              .font(.subheadline)
          }
        })
        Button(action: {
          model.action = "Hide"
          updateAction(.hide)
        }, label: {
          HStack {
            Image(systemName: "eye.slash")
            Text("Hide")
              .font(.subheadline)
          }
        })
        Button(action: {
          model.action = "Unhide"
          updateAction(.unhide)
        }, label: {
          HStack {
            Image(systemName: "eye")
            Text("Unhide")
              .font(.subheadline)
          }
        })
        Button(action: {
          model.action = "Peek"
          updateAction(.peek)
        }, label: {
          HStack {
            Image(systemName: "eyes")
            Text("Peek")
              .font(.subheadline)
          }
        })
      }, label: {
        Text(model.action)
          .font(.caption)
          .fixedSize(horizontal: false, vertical: true)
          .truncationMode(.middle)
          .allowsTightening(true)
      })
      .menuStyle(.zen(.init(color: .systemGray)))
      .fixedSize()
      .compositingGroup()

      ZenDivider(.vertical)
        .fixedSize()

      Grid(alignment: .leading, verticalSpacing: 2) {
        GridRow {
          HStack {
            ZenCheckbox("", style: .small, isOn: $model.inBackground) { newValue in
              updateModifier(.background, newValue: newValue)
            }
            Text("In background")
          }

          HStack {
            ZenCheckbox("", style: .small, isOn: $model.hideWhenRunning) { newValue in
              updateModifier(.hidden, newValue: newValue)
            }
            Text("Hide when opening")
          }

          HStack {
            ZenCheckbox("", style: .small, isOn: $model.ifNotRunning) { newValue in
              updateModifier(.onlyIfNotRunning, newValue: newValue)
            }
            Text("If not running")
          }
        }
        GridRow {
          HStack {
            ZenCheckbox("", style: .small, isOn: $model.addToStage) { newValue in
              updateModifier(.addToStage, newValue: newValue)
            }
            Text("Add to Stage")
          }

          HStack {
            ZenCheckbox("", style: .small, isOn: $model.waitForAppToLaunch) { newValue in
              updateModifier(.waitForAppToLaunch, newValue: newValue)
            }
            Text("Wait for App to Launch")
          }
          Spacer()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .buttonStyle(.regular)
    .lineLimit(1)
    .allowsTightening(true)
    .truncationMode(.tail)
    .font(.caption)
    .enableInjection()
  }

  func updateAction(_ action: ApplicationCommand.Action) {
    updater.modifyCommand(withID: metaData.id, using: transaction) { command in
      guard case .application(var appCommand) = command else { return }
      appCommand.action = action
      command = .application(appCommand)
    }
  }

  func updateModifier(_ modifier: ApplicationCommand.Modifier, newValue: Bool) {
    updater.modifyCommand(withID: metaData.id, using: transaction) { command in
      guard case .application(var appCommand) = command else { return }
      if !appCommand.modifiers.contains(modifier) && newValue {
        appCommand.modifiers.insert(modifier)
      } else if appCommand.modifiers.contains(modifier) && !newValue {
        appCommand.modifiers.remove(modifier)
      }
      command = .application(appCommand)
    }
  }
}

struct ApplicationCommandImageView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject var applicationStore: ApplicationStore
  @State private var isHovered: Bool = false
  @State private var metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, iconSize: CGSize) {
    _metaData = .init(initialValue: metaData)
    self.iconSize = iconSize
  }

  var body: some View {
    Menu(content: {
      ForEach(applicationStore.applications.lazy, id: \.path) { app in
        Button(action: {
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case .application(var applicationCommand) = command else { return }
            applicationCommand.application = app
            command = .application(applicationCommand)
          }
          metaData.icon = .init(bundleIdentifier: app.bundleIdentifier, path: app.path)
        }, label: {
          let text = app.metadata.isSafariWebApp
          ? "\(app.displayName) (Safari Web App)"
          : app.displayName
          Text(text)
        })
      }
    }, label: { })
    .contentShape(Rectangle())
    .menuStyle(IconMenuStyle())
    .padding(4)
    .overlay(content: {
      IconView(icon: metaData.icon, size: iconSize)
        .fixedSize()
        .allowsHitTesting(false)
        .opacity(metaData.icon != nil ? 1 : 0)
    })
  }
}

struct IconMenuStyle: MenuStyle {
  func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
  }
}

struct ApplicationCommandView_Previews: PreviewProvider {
  static let command = DesignTime.applicationCommand
  static var previews: some View {
    ApplicationCommandView(
      command.model.meta,
      model: command.kind,
      iconSize: .init(width: 24, height: 24)
    )
      .designTime()
  }
}
