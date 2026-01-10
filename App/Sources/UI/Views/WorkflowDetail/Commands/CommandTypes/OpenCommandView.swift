import Apps
import Bonzai
import HotSwiftUI
import SwiftUI

struct OpenCommandView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @State var model: CommandViewModel.Kind.OpenModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.OpenModel, iconSize: CGSize) {
    _model = .init(initialValue: model)
    self.metaData = metaData
    self.iconSize = iconSize
  }

  var body: some View {
    CommandContainerView(metaData, placeholder: model.placeholder, icon: {
      HeaderView(metaData, model: model, iconSize: iconSize)
    }, content: {
      ContentView(metaData: metaData, model: $model)
    }, subContent: {
      SubContentView(model: $model, onReveal: {
        NSWorkspace.shared.selectFile(model.path, inFileViewerRootedAtPath: "")
      }) {
        OpenPanelController().perform(.selectFile(types: [], handler: { path in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            model.path = path
            command = .open(OpenCommand(application: nil, path: path, meta: command.meta))
          }
        }))
      }
    })
    .enableInjection()
  }
}

private struct HeaderView: View {
  private var metaData: CommandViewModel.MetaData
  private let model: CommandViewModel.Kind.OpenModel
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData, model: CommandViewModel.Kind.OpenModel, iconSize: CGSize) {
    self.metaData = metaData
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      switch metaData.icon {
      case let .some(icon):
        if let appPath = model.applicationPath {
          IconView(icon: .init(bundleIdentifier: appPath, path: appPath),
                   size: iconSize)
            .shadow(radius: 3)
            .id("open-with-\(appPath)")
        } else {
          IconView(icon: icon, size: iconSize)
        }
      case .none:
        EmptyView()
      }
    }
  }
}

private struct ContentView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding private var model: CommandViewModel.Kind.OpenModel

  private var metaData: CommandViewModel.MetaData

  init(metaData: CommandViewModel.MetaData, model: Binding<CommandViewModel.Kind.OpenModel>) {
    self.metaData = metaData
    _model = model
  }

  var body: some View {
    HStack(spacing: 2) {
      TextField("", text: $model.path)
        .environment(\.textFieldBackgroundColor, .clear)
        .environment(\.textFieldFont, .callout)
        .environment(\.textFieldPadding, .mini)
        .environment(\.textFieldUnfocusedOpacity, 0.0)
        .onChange(of: model.path, perform: { newValue in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case var .open(openCommand) = command else { return }

            openCommand.path = newValue
            command = .open(openCommand)
          }
        })
        .frame(maxWidth: .infinity)

      Menu(content: {
        ForEach(model.applications.lazy) { app in
          Button(app.displayName, action: {
            model.appName = app.displayName
            model.applicationPath = app.path
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              guard case let .open(openCommand) = command else { return }

              command = .open(OpenCommand(application: app, path: openCommand.path, meta: command.meta))
            }
          })
        }
        Divider()
        Button("Default", action: {
          model.appName = nil
          model.applicationPath = nil
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case let .open(openCommand) = command else { return }

            command = .open(OpenCommand(application: nil, path: openCommand.path, meta: command.meta))
          }
        })
      }, label: {
        Text(model.appName ?? "Default")
          .font(.caption)
          .truncationMode(.middle)
          .lineLimit(1)
          .allowsTightening(true)
          .padding(4)
      })
      .menuIndicator(model.applications.isEmpty ? .hidden : .visible)
      .fixedSize(horizontal: true, vertical: false)
      .opacity(!model.applications.isEmpty ? 1 : 0)
      .frame(width: model.applications.isEmpty ? 0 : nil)
    }
    .enableInjection()
  }
}

private struct SubContentView: View {
  @Binding var model: CommandViewModel.Kind.OpenModel
  private let onEdit: () -> Void
  private let onReveal: () -> Void

  init(model: Binding<CommandViewModel.Kind.OpenModel>,
       onReveal: @escaping () -> Void,
       onEdit: @escaping () -> Void) {
    _model = model
    self.onReveal = onReveal
    self.onEdit = onEdit
  }

  var body: some View {
    HStack {
      let url = URL(fileURLWithPath: (model.path as NSString).expandingTildeInPath)
      let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
      if urlComponents?.scheme == "file" {
        Spacer()
        Button(action: {
          onReveal()
        }, label: {
          Text("Reveal")
            .font(.caption)
        })

        Button(action: {
          onEdit()
        }, label: {
          Text("Edit")
            .font(.caption)
        })
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .font(.caption)
  }
}

struct OpenCommandView_Previews: PreviewProvider {
  static let command = DesignTime.openCommand
  static var previews: some View {
    OpenCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24))
      .designTime()
  }
}
