import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ContentDebounce: DebounceSnapshot {
  let workflows: Set<ContentViewModel.ID>
  let groups: Set<GroupViewModel.ID>
}

struct ContentView: View {
  @ObserveInjection var inject

  enum Action: Hashable {
    case rerender(_ groupIds: Set<WorkflowGroup.ID>)
    case moveWorkflowsToGroup(_ groupId: WorkflowGroup.ID, workflows: Set<ContentViewModel.ID>)
    case selectWorkflow(workflowIds: Set<ContentViewModel.ID>, groupIds: Set<WorkflowGroup.ID>)
    case removeWorflows(Set<ContentViewModel.ID>)
    case moveWorkflows(source: IndexSet, destination: Int)
    case addWorkflow(workflowId: Workflow.ID)
    case addCommands(workflowId: Workflow.ID, commandIds: [DetailViewModel.CommandViewModel.ID])
  }

  static var appStorage: AppStorageStore = .init()

  @Namespace var namespace
  @Environment(\.controlActiveState) var controlActiveState
  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher

  @Environment(\.resetFocus) var resetFocus

  private var focus: FocusState<AppFocus?>.Binding
  private var focusPublisher = FocusPublisher<ContentViewModel>()

  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @ObservedObject private var groupSelectionManager: SelectionManager<GroupViewModel>

  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    _contentSelectionManager = .init(initialValue: contentSelectionManager)
    _groupSelectionManager = .init(initialValue: groupSelectionManager)
    self.focus = focus
    self.onAction = onAction
  }

  var body: some View {
    VStack(spacing: 0) {
      ContentHeaderView(groupSelectionManager: groupSelectionManager,
                        namespace: namespace,
                        onAction: onAction)
      ContentListView(focus,
                      contentSelectionManager: contentSelectionManager,
                      groupSelectionManager: groupSelectionManager,
                      focusPublisher: focusPublisher,
                      onAction: onAction)
      .focused(focus, equals: .workflows)
    }
    .background(
      LinearGradient(stops: [
        .init(color: Color.clear, location: 0.5),
        .init(color: Color(nsColor: .gridColor), location: 1.0),
      ], startPoint: .topLeading, endPoint: .bottomTrailing)
    )
    .focusSection()
    .debugEdit()
  }

  private func divider() -> some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color(nsColor: .textBackgroundColor))
      Rectangle()
        .fill(Color.gray)
        .frame(height: 1)
        .opacity(0.15)
      Rectangle()
        .fill(Color.black)
        .frame(height: 1)
        .opacity(0.5)
    }
    .allowsHitTesting(false)
    .shadow(color: Color(.gridColor), radius: 8, x: 0, y: 2)
    .edgesIgnoringSafeArea(.top)
  }
}

struct ContentView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    ContentView($focus,
                contentSelectionManager: .init(),
                groupSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 900)
  }
}
