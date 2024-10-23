import Apps
import Bonzai
import Inject
import SwiftUI

struct ApplicationCommandView: View {
  enum Action {
    case changeApplication(Application)
    case updateName(newName: String)
    case changeApplicationModifier(modifier: ApplicationCommand.Modifier, newValue: Bool)
    case changeApplicationAction(ApplicationCommand.Action)
    case commandAction(CommandContainerAction)
  }

  @ObserveInjection var inject
  private let metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.ApplicationModel
  private let iconSize: CGSize
  private let onAction: (ApplicationCommandView.Action) -> Void

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.ApplicationModel, 
       iconSize: CGSize, onAction: @escaping (ApplicationCommandView.Action) -> Void) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      metaData,
      placeholder: model.placheolder,
      icon: { _ in
        ApplicationCommandImageView(metaData, iconSize: iconSize, onAction: onAction)
      },
      content: { _ in 
        ApplicationCommandInternalView(metaData, model: model,
                                       iconSize: iconSize, onAction: onAction)
        .roundedContainer(4, padding: 4, margin: 0)
      },
      subContent: { metaData in
        ZenCheckbox("Notify", style: .small, isOn: Binding(get: {
          if case .bezel = metaData.notification.wrappedValue { return true } else { return false }
        }, set: { newValue in
          metaData.notification.wrappedValue = newValue ? .bezel : nil
          onAction(.commandAction(.toggleNotify(newValue ? .bezel : nil)))
        })) { value in
          if value {
            onAction(.commandAction(.toggleNotify(metaData.notification.wrappedValue)))
          } else {
            onAction(.commandAction(.toggleNotify(nil)))
          }
        }
        .offset(x: 1)
      },
      onAction: { action in
        onAction(.commandAction(action))
      }
    )
    .enableInjection()
  }
}

private struct ApplicationCommandInternalView: View {
  @ObserveInjection var inject
  @EnvironmentObject private var applicationStore: ApplicationStore
  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.ApplicationModel
  private let debounce: DebounceManager<String>
  private let iconSize: CGSize
  private let onAction: (ApplicationCommandView.Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.ApplicationModel,
       iconSize: CGSize,
       onAction: @escaping (ApplicationCommandView.Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.onAction = onAction
    self.iconSize = iconSize
    self.debounce = DebounceManager(for: .milliseconds(500)) { newName in
      onAction(.updateName(newName: newName))
    }
  }

  var body: some View {
    HStack(spacing: 4) {
      Menu(content: {
        Button(action: {
          model.action = "Open"
          onAction(.changeApplicationAction(.open))
        }, label: {
          HStack {
            Image(systemName: "power")
            Text("Open")
              .font(.subheadline)
          }
        })

        Button(action: {
          model.action = "Close"
          onAction(.changeApplicationAction(.close))
        }, label: {
          HStack {
            Image(systemName: "poweroff")
            Text("Close")
              .font(.subheadline)
          }
        })
        Button(action: {
          model.action = "Hide"
          onAction(.changeApplicationAction(.hide))
        }, label: {
          HStack {
            Image(systemName: "eye.slash")
            Text("Hide")
              .font(.subheadline)
          }
        })
        Button(action: {
          model.action = "Unhide"
          onAction(.changeApplicationAction(.unhide))
        }, label: {
          HStack {
            Image(systemName: "eye")
            Text("Unhide")
              .font(.subheadline)
          }
        })
        Button(action: {
          model.action = "Peek"
          onAction(.changeApplicationAction(.peek))
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
              onAction(.changeApplicationModifier(modifier: .background, newValue: newValue))
            }
            Text("In background")
          }

          HStack {
            ZenCheckbox("", style: .small, isOn: $model.hideWhenRunning) { newValue in
              onAction(.changeApplicationModifier(modifier: .hidden, newValue: newValue))
            }
            Text("Hide when opening")
          }

          HStack {
            ZenCheckbox("", style: .small, isOn: $model.ifNotRunning) { newValue in
              onAction(.changeApplicationModifier(modifier: .onlyIfNotRunning, newValue: newValue))
            }
            Text("If not running")
          }
        }
        GridRow {
          HStack {
            ZenCheckbox("", style: .small, isOn: $model.addToStage) { newValue in
              onAction(.changeApplicationModifier(modifier: .addToStage, newValue: newValue))
            }
            Text("Add to Stage")
          }

          HStack {
            ZenCheckbox("", style: .small, isOn: $model.waitForAppToLaunch) { newValue in
              onAction(.changeApplicationModifier(modifier: .waitForAppToLaunch, newValue: newValue))
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
}

struct ApplicationCommandImageView: View {
  @EnvironmentObject var applicationStore: ApplicationStore
  @State private var isHovered: Bool = false
  @State private var metaData: CommandViewModel.MetaData
  private let onAction: (ApplicationCommandView.Action) -> Void
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       iconSize: CGSize,
       onAction: @escaping (ApplicationCommandView.Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    Menu(content: {
      ForEach(applicationStore.applications.lazy, id: \.path) { app in
        Button(action: {
          onAction(.changeApplication(app))
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
    ) { _ in }
      .designTime()
  }
}
