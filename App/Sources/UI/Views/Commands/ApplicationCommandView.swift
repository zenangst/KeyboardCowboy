import Apps
import SwiftUI

struct IconMenuStyle: MenuStyle {
  func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .menuStyle(.borderlessButton)
  }
}

struct ApplicationCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case changeApplication(Application)
    case updateName(newName: String)
    case changeApplicationModifier(modifier: ApplicationCommand.Modifier, newValue: Bool)
    case changeApplicationAction(ApplicationCommand.Action)
    case commandAction(CommandContainerAction)
  }

  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.ApplicationModel

  @EnvironmentObject var applicationStore: ApplicationStore

  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.ApplicationModel,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView(
      $metaData,
      icon: { metaData in
        if let icon = metaData.icon.wrappedValue {
          ApplicationCommandImageView($metaData, icon: icon, onAction: onAction)
            .id(metaData.wrappedValue.icon?.bundleIdentifier)
        }
      },
      content: { command in
        HStack(spacing: 8) {
          Menu(content: {
            Button("Open", action: {
              model.action = "Open"
              onAction(.changeApplicationAction(.open)) })
            Button("Close", action: {
              model.action = "Close"
              onAction(.changeApplicationAction(.close)) })
          }, label: {
            HStack(spacing: 4) {
              Text(model.action)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .truncationMode(.middle)
                .allowsTightening(true)
            }
            .padding(4)
          })
          .menuStyle(GradientMenuStyle(.init(nsColor: .systemGray, grayscaleEffect: false)))
          .compositingGroup()

          TextField("", text: $metaData.name)
            .textFieldStyle(AppTextFieldStyle())
            .onChange(of: metaData.name, perform: {
              onAction(.updateName(newName: $0))
            })
        }
      }, subContent: { _ in
        HStack {
          Toggle("In background", isOn: $model.inBackground)
            .onChange(of: model.inBackground) { newValue in
              onAction(.changeApplicationModifier(modifier: .background, newValue: newValue))
            }
          Toggle("Hide when opening", isOn: $model.hideWhenRunning)
            .onChange(of: model.hideWhenRunning) { newValue in
              onAction(.changeApplicationModifier(modifier: .hidden, newValue: newValue))
            }
          Toggle("If not running", isOn: $model.ifNotRunning)
            .onChange(of: model.ifNotRunning) { newValue in
              onAction(.changeApplicationModifier(modifier: .onlyIfNotRunning, newValue: newValue))
            }
        }
      },
      onAction: { onAction(.commandAction($0)) })
    .debugEdit()
    .frame(height: 80)
    .fixedSize(horizontal: false, vertical: true)
    .id(metaData.id)
  }
}

struct ApplicationCommandImageView: View {
  @EnvironmentObject var applicationStore: ApplicationStore
  @State var isHovered: Bool = false
  @Binding private var metaData: CommandViewModel.MetaData
  private let icon: IconViewModel
  private let onAction: (ApplicationCommandView.Action) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       icon: IconViewModel,
       onAction: @escaping (ApplicationCommandView.Action) -> Void) {
    _metaData = metaData
    self.icon = icon
    self.onAction = onAction
  }

  var body: some View {
    Menu(content: {
      ForEach(applicationStore.applications) { app in
        Button(action: {
          onAction(.changeApplication(app))
          metaData.icon = .init(bundleIdentifier: app.bundleIdentifier, path: app.path)
        }, label: {
          Text(app.displayName)
        })
      }
    }, label: { })
    .contentShape(Rectangle())
    .menuStyle(IconMenuStyle())
    .overlay(
      ZStack {
        Color.accentColor.opacity(0.375)
          .frame(width: 32, height: 32)
          .cornerRadius(8, antialiased: false)
        IconView(icon: icon, size: .init(width: 24, height: 24))
          .fixedSize()
      }
        .allowsHitTesting(false)
    )
    .menuIndicator(.hidden)
  }
}

struct ApplicationCommandView_Previews: PreviewProvider {
  static let command = DesignTime.applicationCommand
  static var previews: some View {
    ApplicationCommandView(command.model.meta, model: command.kind) { _ in }
      .designTime()
      .frame(maxHeight: 80)
  }
}
