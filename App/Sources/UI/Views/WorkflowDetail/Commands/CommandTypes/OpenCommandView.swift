import Apps
import Bonzai
import Inject
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
    CommandContainerView(metaData, placeholder: model.placheolder, icon: { command in
      OpenCommandHeaderView(command, model: model, iconSize: iconSize)
    }, content: { command in
      OpenCommandContentView(metaData: metaData, model: $model)
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
      OpenCommandSubContentView(model: $model) {
        NSWorkspace.shared.selectFile(model.path, inFileViewerRootedAtPath: "")
      }
    })
    .enableInjection()
  }
}

private struct OpenCommandHeaderView: View {
  private var command: Binding<CommandViewModel.MetaData>
  private let model: CommandViewModel.Kind.OpenModel
  private let iconSize: CGSize

  init(_ command: Binding<CommandViewModel.MetaData>, model: CommandViewModel.Kind.OpenModel, iconSize: CGSize) {
    self.command = command
    self.model = model
    self.iconSize = iconSize
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      switch command.icon.wrappedValue {
      case .some(let icon):
        IconView(icon: icon, size: iconSize)
        if let appPath = model.applicationPath {
          IconView(icon: .init(bundleIdentifier: appPath, path: appPath),
                   size: iconSize.applying(.init(scaleX: 0.5, y: 0.5)))
          .shadow(radius: 3)
          .id("open-with-\(appPath)")
        }
      case .none:
        EmptyView()
      }
    }
  }
}

private struct OpenCommandContentView: View {
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
        .textFieldStyle(
          .zen(
            .init(
              backgroundColor: Color.clear,
              font: .callout,
              padding: .init(horizontal: .zero, vertical: .zero),
              unfocusedOpacity: 0.0
            )
          )
        )
        .onChange(of: model.path, perform: { newValue in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case .open(var openCommand) = command else { return }
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
              guard case .open(let openCommand) = command else { return }
              command = .open(OpenCommand(application: app, path: openCommand.path, meta: command.meta))
            }

          })
        }
        Divider()
        Button("Default", action: {
          model.appName = nil
          model.applicationPath = nil
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            guard case .open(var openCommand) = command else { return }
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
      .menuStyle(.zen(.init(color: .systemGray, grayscaleEffect: .constant(false))))
      .menuIndicator(model.applications.isEmpty ? .hidden : .visible)
      .fixedSize(horizontal: true, vertical: false)
      .opacity(!model.applications.isEmpty ? 1 : 0)
      .frame(width: model.applications.isEmpty ? 0 : nil)
    }
    .enableInjection()
  }
}

private struct OpenCommandSubContentView: View {
  @Binding var model: CommandViewModel.Kind.OpenModel
  private let onReveal: () -> Void

  init(model: Binding<CommandViewModel.Kind.OpenModel>, onReveal: @escaping () -> Void) {
    _model = model
    self.onReveal = onReveal
  }

  var body: some View {
    HStack {
      if model.path.hasPrefix("http") == false {
        Spacer()
        Button("Reveal", action: onReveal)
          .buttonStyle(.zen(.init(color: .systemBlue)))
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
