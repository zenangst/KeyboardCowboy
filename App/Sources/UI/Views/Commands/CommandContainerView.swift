import SwiftUI
import Inject
import Bonzai

enum CommandContainerAction {
  case run
  case delete
  case changeDelay(Double?)
  case toggleIsEnabled(Bool)
  case toggleNotify(Bool)
  case updateName(newName: String)
}

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  private let placeholder: String

  @Binding private var metaData: CommandViewModel.MetaData
  @ViewBuilder
  private let icon: (Binding<CommandViewModel.MetaData>) -> IconContent
  @ViewBuilder
  private let content: (Binding<CommandViewModel.MetaData>) -> Content
  @ViewBuilder
  private let subContent: (Binding<CommandViewModel.MetaData>) -> SubContent
  private let onAction: (CommandContainerAction) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       placeholder: String,
       @ViewBuilder icon: @escaping (Binding<CommandViewModel.MetaData>) -> IconContent,
       @ViewBuilder content: @escaping (Binding<CommandViewModel.MetaData>) -> Content,
       @ViewBuilder subContent: @escaping (Binding<CommandViewModel.MetaData>) -> SubContent,
       onAction: @escaping (CommandContainerAction) -> Void) {
    _metaData = metaData
    self.icon = icon
    self.placeholder = placeholder
    self.content = content
    self.subContent = subContent
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      CommandContainerHeaderView($metaData, placeholder: placeholder, onAction: onAction)
      ZenDivider()
      CommandContainerContentView($metaData, icon: icon, content: content)
      CommandContainerSubContentView($metaData, content: subContent, onAction: onAction)
    }
    .roundedContainer(padding: 0, margin: 1)
  }
}

private struct CommandContainerHeaderView: View {
  @Binding private var metaData: CommandViewModel.MetaData
  private let placeholder: String
  private let onAction: (CommandContainerAction) -> Void
  private let debounce: DebounceManager<String>

  init(_ metaData: Binding<CommandViewModel.MetaData>, placeholder: String,
       onAction: @escaping (CommandContainerAction) -> Void) {
    _metaData = metaData
    self.placeholder = placeholder
    self.onAction = onAction
    self.debounce = DebounceManager(for: .milliseconds(500)) { newName in
      onAction(.updateName(newName: newName))
    }
  }

  var body: some View {
    HStack(spacing: 8) {
      ZenToggle(config: .init(color: .systemGreen), style: .small, isOn: $metaData.isEnabled) {
        onAction(.toggleIsEnabled($0))
      }
      .offset(x: 1)

      let textFieldPlaceholder = metaData.namePlaceholder.isEmpty
      ? placeholder
      : metaData.namePlaceholder
      TextField(textFieldPlaceholder, text: $metaData.name)
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
        .onChange(of: metaData.name, perform: { debounce.send($0) })

      CommandContainerActionView(onAction: onAction)
    }
    .padding(.horizontal, 8)
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
    HStack(alignment: .top, spacing: 8) {
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.black.opacity(0.2))
        .frame(width: 28, height: 28)
        .overlay { icon($metaData) }
      content($metaData)
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
        .padding([.top, .trailing], 2)
    }
    .padding(.leading, 6)
    .padding(.trailing, 4)
  }
}

private struct CommandContainerSubContentView<Content>: View where Content: View {
  @Binding var metaData: CommandViewModel.MetaData
  @EnvironmentObject var publisher: CommandsPublisher
  private let content: (Binding<CommandViewModel.MetaData>) -> Content
  private let onAction: (CommandContainerAction) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       content: @escaping (Binding<CommandViewModel.MetaData>) -> Content,
       onAction: @escaping (CommandContainerAction) -> Void) {
    _metaData = metaData
    self.content = content
    self.onAction = onAction
  }

  var body: some View {
    HStack(spacing: 8) {
      // Fix this bug that you can't notify when running
      // modifying a menubar command.
      ZenCheckbox("Notify", style: .small, isOn: $metaData.notification) {
        onAction(.toggleNotify($0))
      }
      .offset(x: 2)

      CommandContainerDelayView(
        metaData: $metaData,
        execution: publisher.data.execution,
        onChange: { onAction(.changeDelay($0)) }
      )
      content($metaData)
      Spacer()

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
  let onAction: (CommandContainerAction) -> Void

  var body: some View {
    HStack(spacing: 0) {
      Button(action: { onAction(.delete) },
             label: {
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
      .constant(command.model.meta),
      placeholder: "Placeholder",
      icon: { _ in
        Text("Icon")
      }, content: { _ in
        Text("Content")
      }, subContent: { _ in
        Text("SubContent")
      }, onAction: { _ in })
    .designTime()
  }
}
