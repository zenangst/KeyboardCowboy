import SwiftUI
import Inject
import Bonzai

enum CommandContainerAction {
  case run
  case delete
  case changeDelay(Double?)
  case toggleIsEnabled(Bool)
  case toggleNotify(Command.Notification?)
  case updateName(newName: String)
}

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  private let placeholder: String

  @State private var metaData: CommandViewModel.MetaData
  @ViewBuilder
  private let icon: (Binding<CommandViewModel.MetaData>) -> IconContent
  @ViewBuilder
  private let content: (Binding<CommandViewModel.MetaData>) -> Content
  @ViewBuilder
  private let subContent: (Binding<CommandViewModel.MetaData>) -> SubContent

  init(_ metaData: CommandViewModel.MetaData,
       placeholder: String,
       @ViewBuilder icon: @escaping (Binding<CommandViewModel.MetaData>) -> IconContent,
       @ViewBuilder content: @escaping (Binding<CommandViewModel.MetaData>) -> Content,
       @ViewBuilder subContent: @escaping (Binding<CommandViewModel.MetaData>) -> SubContent = { _ in EmptyView() }) {
    _metaData = .init(initialValue: metaData)
    self.icon = icon
    self.placeholder = placeholder
    self.content = content
    self.subContent = subContent
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      CommandContainerHeaderView($metaData, placeholder: placeholder)
      ZenDivider()
        .padding(.bottom, 4)
      CommandContainerContentView($metaData, icon: icon, content: content)
      CommandContainerSubContentView($metaData, content: subContent)
    }
    .roundedContainer(padding: 0, margin: 1)
  }
}

private struct CommandContainerHeaderView: View {
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
      ZenToggle(config: .init(color: .systemGreen), style: .small, isOn: $metaData.isEnabled) { newValue in
        updater.modifyCommand(withID: metaData.id, using: transaction, handler: { $0.isEnabled = newValue })
      }
      .offset(x: 2)

      let textFieldPlaceholder = metaData.namePlaceholder.isEmpty
      ? placeholder
      : metaData.namePlaceholder
      TextField(textFieldPlaceholder, text: $metaData.name)
        .textFieldStyle(
          .zen(.init(backgroundColor: Color.clear, font: .callout,
                     padding: .init(horizontal: .zero, vertical: .zero),
                     unfocusedOpacity: 0.0)))
        .onChange(of: metaData.name, perform: { newValue in
          updater.modifyCommand(withID: metaData.id, using: transaction, handler: { $0.name = newValue })
        })
      CommandContainerActionView()
    }
    .padding(.horizontal, 6)
    .padding(.top, 6)
  }
}

private struct CommandContainerContentView<IconContent, Content>: View where IconContent: View,
                                                                             Content: View {
  @ViewBuilder
  private let icon: (Binding<CommandViewModel.MetaData>) -> IconContent
  @ViewBuilder
  private let content: (Binding<CommandViewModel.MetaData>) -> Content
  @Binding private var metaData: CommandViewModel.MetaData

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       icon: @escaping (Binding<CommandViewModel.MetaData>) -> IconContent,
       content: @escaping (Binding<CommandViewModel.MetaData>) -> Content) {
    self.icon = icon
    self.content = content
    _metaData = metaData
  }

  var body: some View {
    HStack(alignment: .top, spacing: 6) {
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.black.opacity(0.2))
        .frame(width: 28, height: 28)
        .overlay { icon($metaData) }
        .padding(.leading, 6)
      content($metaData)
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
        .padding(.trailing, 6)
    }
  }
}

private struct CommandContainerSubContentView<Content>: View where Content: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @Binding var metaData: CommandViewModel.MetaData
  @EnvironmentObject var publisher: CommandsPublisher
  private let content: (Binding<CommandViewModel.MetaData>) -> Content

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       content: @escaping (Binding<CommandViewModel.MetaData>) -> Content) {
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
      content($metaData)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .buttonStyle(.regular)
    .lineLimit(1)
    .allowsTightening(true)
    .truncationMode(.tail)
    .font(.caption)
  }
}

private struct CommandContainerActionView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction

  var body: some View {
    HStack(spacing: 0) {
      Button(action: {
        updater.modifyWorkflow(using: transaction) { workflow in
          workflow.commands.removeAll(where: { $0.id == transaction.workflowID })
        }
      }, label: {
        Image(systemName: "xmark")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 10, height: 10)
      })
      .help("Delete Command")
      .buttonStyle(.calm(color: .systemRed, padding: .medium))
    }
  }
}

struct CommandContainerView_Previews: PreviewProvider {
  static let command = DesignTime.applicationCommand

  static var previews: some View {
    CommandContainerView(
      command.model.meta,
      placeholder: "Placeholder",
      icon: { _ in
        Text("Icon")
      }, content: { _ in
        Text("Content")
      }, subContent: { _ in
        Text("SubContent")
      })
    .designTime()
  }
}
