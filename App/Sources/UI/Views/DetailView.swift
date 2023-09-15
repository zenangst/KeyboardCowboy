import SwiftUI

struct DetailView: View {
  enum Action {
    case singleDetailView(SingleDetailView.Action)
  }

  var focus: FocusState<AppFocus?>.Binding
  @EnvironmentObject var statePublisher: DetailStatePublisher
  private var onAction: (DetailView.Action) -> Void

  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       onAction: @escaping (DetailView.Action) -> Void) {
    self.focus = focus
    self.onAction = onAction
    self.commandSelectionManager = commandSelectionManager
    self.applicationTriggerSelectionManager = applicationTriggerSelectionManager
    self.keyboardShortcutSelectionManager = keyboardShortcutSelectionManager
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
        focus,
        applicationTriggerSelectionManager: applicationTriggerSelectionManager,
        commandSelectionManager: commandSelectionManager,
        keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
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
    DetailView($focus, applicationTriggerSelectionManager: .init(),
               commandSelectionManager: .init(),
               keyboardShortcutSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 650)
  }
}
