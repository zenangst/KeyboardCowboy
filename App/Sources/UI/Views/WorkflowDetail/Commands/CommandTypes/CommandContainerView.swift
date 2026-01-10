import Bonzai
import HotSwiftUI
import SwiftUI

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
  Content: View,
  SubContent: View {
  @ObserveInjection var inject
  private let placeholder: String

  @State private var metaData: CommandViewModel.MetaData
  private let icon: () -> IconContent
  private let content: () -> Content
  private let subContent: () -> SubContent

  init(_ metaData: CommandViewModel.MetaData,
       placeholder: String,
       @ViewBuilder icon: @escaping () -> IconContent,
       @ViewBuilder content: @escaping () -> Content,
       @ViewBuilder subContent: @escaping () -> SubContent = { EmptyView() }) {
    _metaData = .init(initialValue: metaData)
    self.icon = icon
    self.placeholder = placeholder
    self.content = content
    self.subContent = subContent
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HeaderView($metaData, placeholder: placeholder)
        .environment(\.switchStyle, .small)

      ZenDivider()

      ContentView(icon: icon, content: content)

      let backgroundColor = Color.black.blended(withFraction: 0.3, of: .white)

      SubView($metaData, content: subContent)
        .textStyle {
          $0.font = .caption2
        }
        .environment(\.buttonCalm, false)
        .environment(\.buttonBackgroundColor, backgroundColor)
        .environment(\.buttonHoverEffect, true)
        .environment(\.buttonPadding, .small)
        .environment(\.buttonUnfocusedOpacity, 0.3)
        .environment(\.buttonGrayscaleEffect, true)
        .environment(\.menuBackgroundColor, backgroundColor)
        .environment(\.menuHoverEffect, true)
        .environment(\.menuCalm, false)
        .environment(\.menuPadding, .small)
        .environment(\.menuUnfocusedOpacity, 0.3)
        .environment(\.menuGrayscaleEffect, true)
    }
    .roundedStyle()
    .enableInjection()
  }
}

private struct HeaderView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  @Binding private var metaData: CommandViewModel.MetaData
  private let placeholder: String

  init(_ metaData: Binding<CommandViewModel.MetaData>, placeholder: String) {
    _metaData = metaData
    self.placeholder = placeholder
  }

  var body: some View {
    HStack(spacing: 12) {
      Toggle(isOn: $metaData.isEnabled, label: {})
        .onChange(of: metaData.isEnabled) { newValue in
          updater.modifyCommand(withID: metaData.id, using: transaction, handler: { $0.isEnabled = newValue })
        }
        .padding(.leading, 3)
        .switchStyle(.small)

      let textFieldPlaceholder = metaData.namePlaceholder.isEmpty
        ? placeholder
        : metaData.namePlaceholder

      TextField(textFieldPlaceholder, text: $metaData.name)
        .textFieldStyle()
        .environment(\.textFieldFont, .headline)
        .environment(\.textFieldUnfocusedOpacity, 0)
        .onChange(of: metaData.name, perform: { newValue in
          updater.modifyCommand(withID: metaData.id, using: transaction, handler: { $0.name = newValue })
        })

      CommandContainerActionView(metaData: metaData)
    }
    .enableInjection()
  }
}

private struct ContentView<IconContent, Content>: View where IconContent: View, Content: View {
  private let icon: () -> IconContent
  private let content: () -> Content

  init(icon: @escaping () -> IconContent,
       content: @escaping () -> Content) {
    self.icon = icon
    self.content = content
  }

  var body: some View {
    HStack(alignment: .top, spacing: 6) {
      RoundedRectangle(cornerRadius: 6)
        .fill(Color.black.opacity(0.2))
        .frame(width: 34, height: 34)
        .overlay { icon() }
        .fixedSize()
        .padding(1)

      content()
        .environment(\.menuCalm, false)
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
        .style(.subItem)
        .roundedSubStyle(padding: 1)
    }
  }
}

private struct SubView<Content>: View where Content: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var metaData: CommandViewModel.MetaData
  @EnvironmentObject var publisher: CommandsPublisher
  private let content: () -> Content

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       content: @escaping () -> Content) {
    _metaData = metaData
    self.content = content
  }

  var body: some View {
    HStack(spacing: 8) {
      CommandContainerDelayView(
        metaData: $metaData,
        execution: publisher.data.execution,
        onChange: { newValue in
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            command.delay = newValue
          }
        },
      )

      Menu {
        Button(action: {
          updater.modifyCommand(withID: metaData.id, using: transaction) { command in
            metaData.notification = .none
            command.notification = .none
          }
        }, label: { Text("None") })

        ForEach(Command.Notification.allCases) { notification in
          Button(action: {
            metaData.notification = notification
            updater.modifyCommand(withID: metaData.id, using: transaction) { command in
              command.notification = notification
            }
          }, label: {
            Text(notification.displayValue)
          })
        }
      } label: {
        HStack {
          Image(systemName: "app.badge")
          switch metaData.notification {
          case .bezel: Text("Bezel").font(.caption)
          case .capsule: Text("Capsule").font(.caption)
          case .commandPanel: Text("Command Panel").font(.caption)
          case .none: Text("None").font(.caption)
          }
        }
      }
      .fixedSize()
      content()
    }
    .lineLimit(1)
    .allowsTightening(true)
    .truncationMode(.tail)
    .enableInjection()
  }
}

private struct CommandContainerActionView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  private let metaData: CommandViewModel.MetaData

  init(metaData: CommandViewModel.MetaData) {
    self.metaData = metaData
  }

  var body: some View {
    Button(action: {
      updater.modifyWorkflow(using: transaction, withAnimation: .snappy(duration: 0.125)) { workflow in
        workflow.commands.removeAll(where: { $0.id == metaData.id })
      }
    }, label: {
      Image(systemName: "xmark")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 8, height: 10)
    })
    .environment(\.buttonCalm, true)
    .environment(\.buttonBackgroundColor, .systemRed)
    .environment(\.buttonPadding, .medium)
    .help("Delete Command")
    .enableInjection()
  }
}

struct CommandContainerView_Previews: PreviewProvider {
  static let command = DesignTime.applicationCommand

  static var previews: some View {
    CommandContainerView(
      command.model.meta,
      placeholder: "Placeholder",
      icon: {
        Text("Icon")
      }, content: {
        Text("Content")
      }, subContent: {
        Text("SubContent")
      },
    )
    .designTime()
  }
}
