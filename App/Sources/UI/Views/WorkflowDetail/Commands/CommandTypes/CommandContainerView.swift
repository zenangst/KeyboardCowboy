import SwiftUI
import Inject
import Bonzai

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  @ObserveInjection var inject
  private let placeholder: String

  @State private var metaData: CommandViewModel.MetaData
  @ViewBuilder private let icon: () -> IconContent
  @ViewBuilder private let content: () -> Content
  @ViewBuilder private let subContent: () -> SubContent

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
        .switchStyle {
          $0.style = .small
        }

      ZenDivider()

      ContentView($metaData, icon: icon, content: content)

      SubView($metaData, content: subContent)
        .textStyle {
          $0.font = .caption
        }
        .menuStyle {
          $0.calm = false
          $0.padding = .medium
        }
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

      let textFieldPlaceholder = metaData.namePlaceholder.isEmpty
      ? placeholder
      : metaData.namePlaceholder
      TextField(textFieldPlaceholder, text: $metaData.name)
        .textFieldStyle { textField in
          textField.font = .headline
          textField.unfocusedOpacity = 0
        }
        .onChange(of: metaData.name, perform: { newValue in
          updater.modifyCommand(withID: metaData.id, using: transaction, handler: { $0.name = newValue })
        })

      CommandContainerActionView(metaData: metaData)
    }
    .enableInjection()
  }
}

private struct ContentView<IconContent, Content>: View where IconContent: View,
                                                                             Content: View {
  @ViewBuilder private let icon: () -> IconContent
  @ViewBuilder private let content: () -> Content
  @Binding private var metaData: CommandViewModel.MetaData

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       icon: @escaping () -> IconContent,
       content: @escaping () -> Content) {
    self.icon = icon
    self.content = content
    _metaData = metaData
  }

  var body: some View {
    HStack(alignment: .top, spacing: 6) {
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.black.opacity(0.2))
        .frame(width: 28, height: 28)
        .overlay { icon() }
      content()
        .menuStyle { menu in
          menu.calm = false
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
        .style(.subItem)
        .roundedSubStyle(padding: 1)
    }
  }
}

private struct SubView<Content>: View where Content: View {
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
        }
      )
      content()
    }
    .lineLimit(1)
    .allowsTightening(true)
    .truncationMode(.tail)
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
    .buttonStyle({ style in
      style.calm = true
      style.backgroundColor = .systemRed
      style.padding = .medium
    })
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
      })
    .designTime()
  }
}
