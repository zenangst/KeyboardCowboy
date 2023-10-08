import SwiftUI

enum CommandContainerAction {
  case run
  case delete
  case changeDelay(Double?)
  case toggleIsEnabled(Bool)
  case toggleNotify(Bool)
}

struct CommandContainerView<IconContent, Content, SubContent>: View where IconContent: View,
                                                                          Content: View,
                                                                          SubContent: View {
  @State private var delayString: String = ""
  @State private var delayOverlay: Bool = false

  @EnvironmentObject var detailPublisher: DetailPublisher
  @Binding private var metaData: CommandViewModel.MetaData
  @ViewBuilder
  private let icon: (Binding<CommandViewModel.MetaData>) -> IconContent
  @ViewBuilder
  private let content: (Binding<CommandViewModel.MetaData>) -> Content
  @ViewBuilder
  private let subContent: (Binding<CommandViewModel.MetaData>) -> SubContent
  private let onAction: (CommandContainerAction) -> Void

  init(_ metaData: Binding<CommandViewModel.MetaData>,
       @ViewBuilder icon: @escaping (Binding<CommandViewModel.MetaData>) -> IconContent,
       @ViewBuilder content: @escaping (Binding<CommandViewModel.MetaData>) -> Content,
       @ViewBuilder subContent: @escaping (Binding<CommandViewModel.MetaData>) -> SubContent,
       onAction: @escaping (CommandContainerAction) -> Void) {
    _metaData = metaData
    self.icon = icon
    self.content = content
    self.subContent = subContent
    self.onAction = onAction
  }

  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .top) {
          icon($metaData)
            .fixedSize()
            .frame(maxWidth: 32, maxHeight: 32)

          content($metaData)
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding([.top, .leading], 8)
        .padding(.bottom, 4)

        HStack(spacing: 0) {
          AppToggle("", onColor: Color(.systemGreen), style: .small, isOn: $metaData.isEnabled) {
            onAction(.toggleIsEnabled($0))
          }
          .padding(.leading, 5)
          .padding(.trailing, 5)

          HStack {
            // Fix this bug that you can't notify when running
            // modifying a menubar command.
            AppCheckbox("Notify", style: .small, isOn: $metaData.notification) {
              onAction(.toggleNotify($0))
            }

            CommandContainerDelayView(
              metaData: $metaData,
              execution: detailPublisher.data.execution,
              onChange: { onAction(.changeDelay($0)) }
            )

            subContent($metaData)
          }
            .buttonStyle(.regular)
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.tail)
            .font(.caption)
            .padding(.leading, 8)
        }
        .padding(.bottom, 8)
        .padding(.leading, 4)
      }
      CommandContainerActionView(onAction: onAction)
    }
  }
}

struct CommandContainerActionView: View {
  let onAction: (CommandContainerAction) -> Void

  var body: some View {
    HStack(spacing: 0) {
      HStack(spacing: 0) {
        Color.gray
          .frame(width: 1)
          .opacity(0.15)
        Color.black
          .frame(width: 1)
          .opacity(0.5)
      }
      .drawingGroup()

      VStack(alignment: .center, spacing: 0) {
        Button(action: { onAction(.delete) },
               label: {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fit)
        })
        .help("Delete Command")
        .buttonStyle(.calm(color: .systemRed, padding: .medium))
        .frame(maxWidth: 20, maxHeight: .infinity)
        .padding(.vertical, 10)

        VStack(spacing: 0) {
          Color.gray
            .frame(height: 1)
            .opacity(0.15)
          Color.black
            .frame(height: 1)
            .opacity(0.5)
        }
        .drawingGroup()

        Button(action: { onAction(.run) },
               label: {
          Image(systemName: "play")
            .resizable()
            .aspectRatio(contentMode: .fit)
        })
        .help("Run Workflow")
        .buttonStyle(.calm(color: .systemGreen, padding: .medium))
        .frame(maxWidth: 20, maxHeight: .infinity)
        .padding(.vertical, 10)
      }
      .frame(width: 32)
      .offset(x: -1, y: 1)
    }
  }
}

struct CommandContainerView_Previews: PreviewProvider {
  static let command = DesignTime.applicationCommand

  static var previews: some View {
    CommandContainerView(
      .constant(command.model.meta),
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
