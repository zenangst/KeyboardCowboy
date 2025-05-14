import Inject
import SwiftUI

struct DetailView: View {
  @EnvironmentObject var statePublisher: DetailStatePublisher
  private let applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>
  private let commandPublisher: CommandsPublisher
  private let commandSelection: SelectionManager<CommandViewModel>
  private let infoPublisher: InfoPublisher
  private let keyboardShortcutSelection: SelectionManager<KeyShortcut>
  private let triggerPublisher: TriggerPublisher
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       applicationTriggerSelection: SelectionManager<DetailViewModel.ApplicationTrigger>,
       commandSelection: SelectionManager<CommandViewModel>,
       keyboardShortcutSelection: SelectionManager<KeyShortcut>,
       triggerPublisher: TriggerPublisher,
       infoPublisher: InfoPublisher,
       commandPublisher: CommandsPublisher) {
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
        .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
    case .single(let viewModel):
      SingleDetailView(
        viewModel,
        focus: focus,
        applicationTriggerSelectionManager: applicationTriggerSelection,
        commandSelectionManager: commandSelection,
        keyboardShortcutSelectionManager: keyboardShortcutSelection,
        triggerPublisher: triggerPublisher,
        infoPublisher: infoPublisher,
        commandPublisher: commandPublisher)
      .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
      .overlay(alignment: .topTrailing, content: {
        DevTagView()
      })
    case .multiple(let viewModels):
      let limit = 5
      let count = viewModels.count
      MultiDetailView( count > limit ? Array(viewModels[0...limit-1]) : viewModels, count: count)
        .edgesIgnoringSafeArea(isRunningPreview ? [] : [.top])
    }
  }
}

private struct DevTagView: View {
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
        .offset(x: 8, y: -4)
        .fixedSize()
    }
  }
}

struct DetailView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    DetailView($focus, applicationTriggerSelection: .init(),
               commandSelection: .init(),
               keyboardShortcutSelection: .init(),
               triggerPublisher: DesignTime.triggerPublisher,
               infoPublisher: DesignTime.infoPublisher,
               commandPublisher: DesignTime.commandsPublisher) 
      .designTime()
      .frame(height: 650)
  }
}
