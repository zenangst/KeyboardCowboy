import SwiftUI

struct DetailView: View {
  @EnvironmentObject var statePublisher: DetailStatePublisher
  private let applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandPublisher: CommandsPublisher
  private let commandSelectionManager: SelectionManager<CommandViewModel>
  private let infoPublisher: InfoPublisher
  private let keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>
  private let triggerPublisher: TriggerPublisher
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelectionManager: SelectionManager<CommandViewModel>,
       keyboardShortcutSelectionManager: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher) {
    self.focus = focus
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
    case .single(let viewModel):
      SingleDetailView(
        viewModel,
        focus: focus,
        applicationTriggerSelectionManager: applicationTriggerSelectionManager,
        commandSelectionManager: commandSelectionManager,
        keyboardShortcutSelectionManager: keyboardShortcutSelectionManager,
        triggerPublisher: triggerPublisher,
        infoPublisher: infoPublisher,
        commandPublisher: commandPublisher)
      .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
      .overlay(alignment: .topTrailing, content: {
        DevTagView()
      })
      .animation(.easeInOut(duration: 0.375), value: statePublisher.data)
      .id(viewModel.id)
    case .multiple(let viewModels):
      let limit = 5
      let count = viewModels.count
      MultiDetailView( count > limit ? Array(viewModels[0...limit-1]) : viewModels, count: count)
        .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
    }
  }
}

private struct DevTagView: View {
  @ViewBuilder
  var body: some View {
    if KeyboardCowboyApp.env() != .production {
      Rectangle()
        .fill(Gradient(colors: [
          Color(.systemYellow),
          Color(nsColor: NSColor.systemYellow.blended(withFraction: 0.3, of: NSColor.black)!)
        ]))
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
        .offset(x: 10, y: -20)
        .fixedSize()
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
               commandPublisher: DesignTime.commandsPublisher) 
      .designTime()
      .frame(height: 650)
  }
}
