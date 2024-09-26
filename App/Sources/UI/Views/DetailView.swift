import SwiftUI

struct DetailView: View {
  enum Action {
    case singleDetailView(SingleDetailView.Action)
  }

  @EnvironmentObject var statePublisher: DetailStatePublisher
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandPublisher: CommandsPublisher
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let infoPublisher: InfoPublisher
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let triggerPublisher: TriggerPublisher
  private var focus: FocusState<AppFocus?>.Binding
  private var onAction: (DetailView.Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher,
       onAction: @escaping (DetailView.Action) -> Void) {
    self.focus = focus
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
        .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
    case .single:
      SingleDetailView(
        focus,
        applicationTriggerSelectionManager: applicationTriggerSelectionManager,
        commandSelectionManager: commandSelectionManager,
        keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
        triggerPublisher: triggerPublisher,
        infoPublisher: infoPublisher,
        commandPublisher: commandPublisher,
        onAction: {
          onAction(.singleDetailView($0))
        })
      .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
      .overlay(alignment: .topTrailing, content: {
        if KeyboardCowboy.env() != .production {
          Rectangle()
            .fill(Gradient(colors: [
              Color(.systemYellow),
              Color(nsColor: NSColor.systemYellow.blended(withFraction: 0.3, of: NSColor.black)!)
            ]))
            .frame(width: 75, height: 20)
            .rotationEffect(.degrees(45))
            .offset(x: 30, y: -30)
            .fixedSize()
        }
      })
      .animation(.easeInOut(duration: 0.375), value: statePublisher.data)
    case .multiple(let viewModels):
      let limit = 5
      let count = viewModels.count
      MultiDetailView( count > limit ? Array(viewModels[0...limit-1]) : viewModels, count: count)
        .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
    }
  }
}

struct DetailView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    DetailView($focus, applicationTriggerSelectionManager: .init(),
               commandSelectionManager: .init(),
               keyboardShortcutSelectionManager: .init(),
               triggerPublisher: DesignTime.triggerPublisher,
               infoPublisher: DesignTime.infoPublisher,
               commandPublisher: DesignTime.commandsPublisher) { _ in }
      .designTime()
      .frame(height: 650)
  }
}
