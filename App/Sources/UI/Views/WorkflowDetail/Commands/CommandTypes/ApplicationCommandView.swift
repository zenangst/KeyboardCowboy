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
      icon: { ApplicationCommandImageView(metaData, iconSize: iconSize) },
      content: {
        ApplicationCommandInternalView(metaData, model: model, iconSize: iconSize)
      },
      subContent: { }
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
      .fixedSize()
      .compositingGroup()

      ZenDivider(.vertical)
        .fixedSize()

      Grid(alignment: .leading, verticalSpacing: 2) {
        GridRow {
          Toggle(isOn: $model.inBackground, label: { Text("In Background") })
            .onChange(of: model.inBackground, perform: { newValue in updateModifier(.background, newValue: newValue) })

          Toggle(isOn: $model.hideWhenRunning, label: { Text("Hide when opening") })
            .onChange(of: model.hideWhenRunning, perform: { newValue in updateModifier(.hidden, newValue: newValue) })

          Toggle(isOn: $model.ifNotRunning, label: { Text("If not running") })
            .onChange(of: model.ifNotRunning, perform: { newValue in updateModifier(.onlyIfNotRunning, newValue: newValue) })

        }
        GridRow {
          Toggle(isOn: $model.addToStage, label: { Text("Add to Stage") })
            .onChange(of: model.addToStage, perform: { newValue in updateModifier(.addToStage, newValue: newValue) })

          Toggle(isOn: $model.waitForAppToLaunch, label: { Text("Wait for App to Launch") })
            .onChange(of: model.waitForAppToLaunch, perform: { newValue in updateModifier(.waitForAppToLaunch, newValue: newValue) })

          Spacer()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .checkboxStyle { style in
        style.font = .caption
        style.style = .small
      }
    }
    .lineLimit(1)
    .allowsTightening(true)
    .truncationMode(.tail)
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
      Button(action: {
        let previousApplication = Application.previousApplication()
        updater.modifyCommand(withID: metaData.id, using: transaction) { command in
          guard case .application(var applicationCommand) = command else { return }
          applicationCommand.application = previousApplication
          command = .application(applicationCommand)
        }
      }, label: {
        Text("Previous Application")
      })

      Divider()

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
    .style(.section(.detail))
    .style(.derived)
    .designTime()
    .frame(maxHeight: 116)
  }
}
