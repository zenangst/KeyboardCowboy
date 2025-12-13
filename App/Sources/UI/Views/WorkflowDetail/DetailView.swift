import HotSwiftUI
import SwiftUI

struct DetailView: View {
  @EnvironmentObject var statePublisher: DetailStatePublisher
  let applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>
  let commandPublisher: CommandsPublisher
  let commandSelection: SelectionManager<CommandViewModel>
  let infoPublisher: InfoPublisher
  let keyboardShortcutSelection: SelectionManager<KeyShortcut>
  let triggerPublisher: TriggerPublisher
  private var focus: FocusState<AppFocus?>.Binding

  init(
    _ focus: FocusState<AppFocus?>.Binding,
    applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>,
    commandSelection: SelectionManager<CommandViewModel>,
    keyboardShortcutSelection: SelectionManager<KeyShortcut>,
    triggerPublisher: TriggerPublisher,
    infoPublisher: InfoPublisher,
    commandPublisher: CommandsPublisher,
  ) {
    self.focus = focus
    self.commandSelection = commandSelection
    self.applicationTriggerSelection = applicationTriggerSelection
    self.keyboardShortcutSelection = keyboardShortcutSelection
    self.triggerPublisher = triggerPublisher
    self.infoPublisher = infoPublisher
    self.commandPublisher = commandPublisher
  }

  var body: some View {
    switch statePublisher.data {
    case .empty:
      DetailEmptyView()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.375), value: statePublisher.data)
    case let .single(viewModel):
      SingleDetailView(
        viewModel,
        focus: focus,
        applicationTriggerSelectionManager: applicationTriggerSelection,
        commandSelectionManager: commandSelection,
        keyboardShortcutSelectionManager: keyboardShortcutSelection,
        triggerPublisher: triggerPublisher,
        infoPublisher: infoPublisher,
        commandPublisher: commandPublisher,
      )
      .overlay(alignment: .topTrailing) {
        DevTagView()
      }
    case let .multiple(viewModels):
      let limit = 5
      let count = viewModels.count
      MultiDetailView(
        count > limit ? Array(viewModels[0 ... limit - 1]) : viewModels,
        count: count,
      )
    }
  }
}

private struct DevTagView: View {
  var body: some View {
    if KeyboardCowboyApp.env() != .production {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color.yellow,
            Color.yellow.opacity(0.3),
          ]),
        )
        .frame(width: 75, height: 20)
        .overlay {
          Text("Develop")
            .foregroundStyle(.black)
            .opacity(0.25)
            .fontWeight(.bold)
            .font(.caption)
            .scaleEffect(0.8)
            .shadow(color: .white, radius: 0, y: 1)
        }
        .rotationEffect(.degrees(45), anchor: .trailing)
        .offset(x: 8, y: -4)
        .fixedSize()
    }
  }
}

#Preview {
  @FocusState var focus: AppFocus?
  DetailView(
    $focus,
    applicationTriggerSelection: .init(),
    commandSelection: .init(),
    keyboardShortcutSelection: .init(),
    triggerPublisher: DesignTime.triggerPublisher,
    infoPublisher: DesignTime.infoPublisher,
    commandPublisher: DesignTime.commandsPublisher,
  )
  .designTime()
  .frame(height: 650)
}
