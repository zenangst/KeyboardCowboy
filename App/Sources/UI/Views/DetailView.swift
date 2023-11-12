import SwiftUI

struct DetailView: View {
  enum Action {
    case singleDetailView(SingleDetailView.Action)
  }

  @EnvironmentObject var statePublisher: DetailStatePublisher
  @FocusState private var focus: AppFocus?
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandPublisher: CommandsPublisher
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let infoPublisher: InfoPublisher
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let triggerPublisher: TriggerPublisher
  private var onAction: (DetailView.Action) -> Void

  init(_ focus: FocusState<AppFocus?>,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher,
       onAction: @escaping (DetailView.Action) -> Void) {
    _focus = focus
    self.onAction = onAction
    self.commandSelectionManager = commandSelectionManager
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
    self.triggerPublisher = triggerPublisher
    self.infoPublisher = infoPublisher
    self.commandPublisher = commandPublisher
  }

  @ViewBuilder
  var body: some View {
    switch statePublisher.data {
    case .empty:
      DetailEmptyView()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.375), value: statePublisher.data)
    case .single:
      SingleDetailView(
        _focus,
        applicationTriggerSelectionManager: applicationTriggerSelectionManager,
        commandSelectionManager: commandSelectionManager,
        keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
        triggerPublisher: triggerPublisher,
        infoPublisher: infoPublisher,
        commandPublisher: commandPublisher,
        onAction: {
          onAction(.singleDetailView($0))
        })
      .animation(.easeInOut(duration: 0.375), value: statePublisher.data)
    case .multiple(let viewModels):
      let limit = 5
      let count = viewModels.count
      MultiDetailView( count > limit ? Array(viewModels[0...limit-1]) : viewModels, count: count)
    }
  }
}

struct DetailView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    DetailView(_focus, applicationTriggerSelectionManager: .init(),
               commandSelectionManager: .init(),
               keyboardShortcutSelectionManager: .init(),
               triggerPublisher: DesignTime.triggerPublisher,
               infoPublisher: DesignTime.infoPublisher,
               commandPublisher: DesignTime.commandsPublisher) { _ in }
      .designTime()
      .frame(height: 650)
  }
}
