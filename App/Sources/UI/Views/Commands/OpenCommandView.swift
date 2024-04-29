import Apps
import Bonzai
import Inject
import SwiftUI

struct OpenCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updatePath(newPath: String)
    case openWith(Application?)
    case commandAction(CommandContainerAction)
    case reveal(path: String)
  }
  @State var model: CommandViewModel.Kind.OpenModel
  private let metaData: CommandViewModel.MetaData
  private let iconSize: CGSize

  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.OpenModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    _model = .init(initialValue: model)
    self.metaData = metaData
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(metaData, placeholder: model.placheolder, icon: { command in
      OpenCommandHeaderView(command, model: model, iconSize: iconSize)
    }, content: { command in
      OpenCommandContentView(command: command, model: $model) { app in
        onAction(.openWith(app))
      } onUpdatePath: { newPath in
        onAction(.updatePath(newPath: newPath))
      }
      .roundedContainer(padding: 4, margin: 0)
    }, subContent: { metaData in
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
      OpenCommandSubContentView(model: $model) {
        onAction(.reveal(path: model.path))
      }
    }, onAction: { onAction(.commandAction($0)) })
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
  @Binding private var model: CommandViewModel.Kind.OpenModel
  private var command: Binding<CommandViewModel.MetaData>
  private let debounce: DebounceManager<String>

  private let onUpdatePath: (String) -> Void
  private let onUpdateOpenWith: (Application?) -> Void

  init(command: Binding<CommandViewModel.MetaData>, model: Binding<CommandViewModel.Kind.OpenModel>, 
       onUpdateOpenWith: @escaping (Application?) -> Void,
       onUpdatePath: @escaping (String) -> Void) {
    _model = model
    self.command = command
    self.onUpdatePath = onUpdatePath
    self.onUpdateOpenWith = onUpdateOpenWith
    self.debounce = DebounceManager(for: .milliseconds(500), onUpdate: onUpdatePath)
  }

  var body: some View {
    HStack(spacing: 2) {
      TextField("", text: $model.path)
        .textFieldStyle(.regular(Color(.windowBackgroundColor)))
        .onChange(of: model.path, perform: { debounce.send($0) })
        .frame(maxWidth: .infinity)

      Menu(content: {
        ForEach(model.applications.lazy) { app in
          Button(app.displayName, action: {
            model.appName = app.displayName
            model.applicationPath = app.path
            onUpdateOpenWith(app)
          })
        }
        Divider()
        Button("Default", action: {
          model.appName = nil
          model.applicationPath = nil
          onUpdateOpenWith(nil)
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
    OpenCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
  }
}
