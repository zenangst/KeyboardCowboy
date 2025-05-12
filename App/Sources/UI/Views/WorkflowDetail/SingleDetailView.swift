import Bonzai
import Inject
import SwiftUI
import Apps

struct SingleDetailView: View {
  @Namespace var namespace

  @EnvironmentObject private var commandPublisher: CommandsPublisher
  @EnvironmentObject private var infoPublisher: InfoPublisher
  @EnvironmentObject private var triggerPublisher: TriggerPublisher

  @State private var overlayOpacity: CGFloat = 0
  private let viewModel: DetailViewModel
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private var focus: FocusState<AppFocus?>.Binding

  init(_ viewModel: DetailViewModel,
       focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher) {
    self.viewModel = viewModel
    self.focus = focus
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.commandSelectionManager = commandSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
  }

  var body: some View {
    ScrollViewReader { proxy in
      VStack(alignment: .leading, spacing: 0) {
          WorkflowInfoView(focus, publisher: infoPublisher, onInsertTab: {
              switch triggerPublisher.data {
              case .applications:      focus.wrappedValue = .detail(.applicationTriggers)
              case .keyboardShortcuts: focus.wrappedValue = .detail(.keyboardShortcuts)
              case .snippet:           focus.wrappedValue = .detail(.addSnippetTrigger)
              case .empty:             focus.wrappedValue = .detail(.addAppTrigger)
              case .modifier: break
              }
            })
          .style(.derived)
          .environmentObject(commandSelectionManager)

          ZenDivider()

          WorkflowTriggerListView(
            focus,
            workflowId: infoPublisher.data.id,
            publisher: triggerPublisher,
            applicationTriggerSelectionManager: applicationTriggerSelectionManager,
            keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
            onTab: {
              if commandPublisher.data.commands.isEmpty {
                focus.wrappedValue = .detail(.addCommand)
              } else {
                focus.wrappedValue = .detail(.commands)
              }
            })
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(alignment: .bottom, content: {
          SingleDetailBackgroundView()
        })

      CommandList(
        focus,
        namespace: namespace,
        workflowId: infoPublisher.data.id,
        isPrimary: Binding<Bool>.init(get: {
          switch triggerPublisher.data {
          case .applications(let array): !array.isEmpty
          case .keyboardShortcuts(let keyboardTrigger): !keyboardTrigger.shortcuts.isEmpty
          case .snippet(let snippet): !snippet.text.isEmpty
          case .empty, .modifier: false
          }
        }, set: { _ in }),
        publisher: commandPublisher,
        triggerPublisher: triggerPublisher,
        selectionManager: commandSelectionManager,
        scrollViewProxy: proxy)
    }
    .focusScope(namespace)
    .frame(maxHeight: .infinity, alignment: .top)
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    let colorSchemes: [ColorScheme] = [.dark]
    HStack(spacing: 0) {
      ForEach(colorSchemes, id: \.self) { colorScheme in
        SingleDetailView(DesignTime.detail,
                         focus: $focus,
                         applicationTriggerSelectionManager: .init(),
                         commandSelectionManager: .init(),
                         keyboardShortcutSelectionManager: .init(),
                         triggerPublisher: DesignTime.triggerPublisher,
                         infoPublisher: DesignTime.infoPublisher,
                         commandPublisher: DesignTime.commandsPublisher) 
          .background()
          .environment(\.colorScheme, colorScheme)
          .style(.section(.detail))
      }
    }
    .designTime()
    .frame(width: 600, height: 900)
  }
}
