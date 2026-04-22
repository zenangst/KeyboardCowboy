@testable import Keyboard_Cowboy
import XCTest

@MainActor
final class ContentViewActionReducerTests: XCTestCase {
  func testReduceContentViewAction_noop() {
    let id = UUID().uuidString
    let ctx = context()
    var subject = subject(id)

    // Nothing should happen because `.rerender` is no-op.
    GroupDetailViewActionReducer.reduce(.refresh([id]), groupStore: ctx.store,
                                        selectionManager: ctx.selector,
                                        group: &subject.original)

    XCTAssertEqual(subject.original, subject.copy)

    // Nothing should happen because `.selectWorkflow` is no-op.
    GroupDetailViewActionReducer.reduce(.selectWorkflow(workflowIds: []), groupStore: ctx.store,
                                        selectionManager: ctx.selector,
                                        group: &subject.original)

    XCTAssertEqual(subject.original, subject.copy)
  }

  func testReduceContentViewAction_moveWorkflowsToGroup() {
    let ctx = context([
      .init(id: "group-1-id", name: "group-1-name", workflows: [
        .init(id: "workflow-1-id", name: "workflow-1-name"),
        .init(id: "workflow-2-id", name: "workflow-2-name"),
      ]),
      .init(id: "group-2-id", name: "group-2-name", workflows: []),
    ])
    let action: GroupDetailView.Action = .moveWorkflowsToGroup("group-2-id",
                                                               workflows: ["workflow-1-id", "workflow-2-id"])
    var subject = ctx.store.groups[0]

    GroupDetailViewActionReducer.reduce(action, groupStore: ctx.store,
                                        selectionManager: ctx.selector,
                                        group: &subject)

    // Verify that the workflows were moved to the new group.
    XCTAssertTrue(ctx.store.groups[0].workflows.isEmpty)
    XCTAssertEqual(ctx.store.groups[1].workflows.map(\.id).sorted(), [
      "workflow-1-id", "workflow-2-id",
    ])
  }

  func testReduceContentViewAction_addWorkflow() {
    let ctx = context([
      .init(id: "group-1-id", name: "group-1-name", workflows: [
        .init(id: "workflow-1-id", name: "workflow-1-name"),
        .init(id: "workflow-2-id", name: "workflow-2-name"),
      ]),
      .init(id: "group-2-id", name: "group-2-name", workflows: []),
    ])
    let action: GroupDetailView.Action = .addWorkflow(workflowId: "workflow-3-id")
    var subject = ctx.store.groups[0]

    XCTAssertEqual(subject.workflows[0].id, "workflow-1-id")
    XCTAssertEqual(subject.workflows[1].id, "workflow-2-id")
    XCTAssertEqual(subject.workflows.count, 2)

    GroupDetailViewActionReducer.reduce(action, groupStore: ctx.store,
                                        selectionManager: ctx.selector,
                                        group: &subject)

    // Verify that a new workflow was added to the group.
    XCTAssertEqual(subject.workflows.count, 3)
    XCTAssertEqual(subject.workflows[0].id, "workflow-1-id")
    XCTAssertEqual(subject.workflows[1].id, "workflow-2-id")
    XCTAssertEqual(subject.workflows[2].id, "workflow-3-id")
  }

  func testReduceContentViewAction_removeWorflows() {
    let ctx = context([
      .init(id: "group-1-id", name: "group-1-name", workflows: [
        .init(id: "workflow-1-id", name: "workflow-1-name"),
        .init(id: "workflow-2-id", name: "workflow-2-name"),
      ]),
      .init(id: "group-2-id", name: "group-2-name", workflows: []),
    ])
    var subject = ctx.store.groups[0]

    XCTAssertEqual(subject.workflows.count, 2)

    // Remove workflow-1-id and check that there is still one left.
    GroupDetailViewActionReducer.reduce(.removeWorkflows(["workflow-1-id"]), groupStore: ctx.store,
                                        selectionManager: ctx.selector,
                                        group: &subject)

    XCTAssertEqual(subject.workflows.count, 1)
    XCTAssertEqual(ctx.selector.selections, ["workflow-2-id"])
    XCTAssertEqual(subject.workflows[0].id, "workflow-2-id")

    // Remove workflow-2-id and check that the workflows are removed.
    GroupDetailViewActionReducer.reduce(.removeWorkflows(["workflow-2-id"]), groupStore: ctx.store,
                                        selectionManager: ctx.selector,
                                        group: &subject)
    XCTAssertTrue(subject.workflows.isEmpty)
    XCTAssertTrue(ctx.selector.selections.isEmpty)
  }

  func testReduceContentViewAction_moveWorkflows() {
    let ctx = context([
      .init(id: "group-1-id", name: "group-1-name", workflows: [
        .init(id: "workflow-1-id", name: "workflow-1-name"),
        .init(id: "workflow-2-id", name: "workflow-2-name"),
        .init(id: "workflow-3-id", name: "workflow-3-name"),
      ]),
      .init(id: "group-2-id", name: "group-2-name", workflows: []),
    ])

    var indexSet = IndexSet()
    indexSet.insert(2)
    let action: GroupDetailView.Action = .reorderWorkflows(source: indexSet, destination: 0)
    var subject = ctx.store.groups[0]

    GroupDetailViewActionReducer.reduce(action, groupStore: ctx.store,
                                        selectionManager: ctx.selector,
                                        group: &subject)

    XCTAssertEqual(subject.workflows.map(\.id), [
      "workflow-3-id",
      "workflow-1-id",
      "workflow-2-id",
    ])
  }

  func testSelectionManagerPublishSynchronizesAnchors() {
    let subject = SelectionManager<GroupViewModel>()

    subject.publish(["group-1-id"])

    XCTAssertEqual(subject.selections, ["group-1-id"])
    XCTAssertEqual(subject.lastSelection, "group-1-id")
    XCTAssertEqual(subject.initialSelection, "group-1-id")

    subject.publish([])

    XCTAssertTrue(subject.selections.isEmpty)
    XCTAssertNil(subject.lastSelection)
    XCTAssertNil(subject.initialSelection)
  }

  func testSelectionManagerPublishPreservesExistingAnchor() {
    let subject = SelectionManager<GroupViewModel>()

    subject.publish(["group-1-id", "group-2-id"])
    subject.setLastSelection("group-2-id")

    subject.publish(["group-1-id", "group-2-id"])

    XCTAssertEqual(subject.lastSelection, "group-2-id")
    XCTAssertEqual(subject.initialSelection, "group-2-id")
  }

  func testSidebarConfigurationSelectionFallsBackToFirstGroup() {
    let store = GroupStore(selectionGroups())
    let selectionManager = SelectionManager<GroupViewModel>()
    let subject = SidebarCoordinator(
      store,
      applicationStore: ApplicationStore.shared,
      groupSelectionManager: selectionManager,
    )

    selectionManager.publish(["missing-group-id"])

    subject.handle(.selectConfiguration("configuration-id"))

    XCTAssertEqual(selectionManager.selections, ["group-1-id"])
    XCTAssertEqual(selectionManager.lastSelection, "group-1-id")
  }

  func testDeleteConfigurationRefreshesContentSelection() {
    let store = GroupStore(selectionGroups())
    let groupSelection = SelectionManager<GroupViewModel>()
    let workflowSelection = SelectionManager<GroupDetailViewModel>()
    let subject = GroupCoordinator(
      store,
      applicationStore: ApplicationStore.shared,
      groupSelectionManager: groupSelection,
      workflowsSelectionManager: workflowSelection,
    )

    groupSelection.publish(["group-1-id"])
    workflowSelection.publish(["workflow-1-id"])
    subject.handle(.selectConfiguration("configuration-id"))

    XCTAssertEqual(subject.contentPublisher.data.map(\.id), ["workflow-1-id", "workflow-2-id"])

    store.groups = []
    subject.handle(.deleteConfiguration(id: "configuration-id"))

    XCTAssertTrue(subject.contentPublisher.data.isEmpty)
    XCTAssertTrue(workflowSelection.selections.isEmpty)
  }

  func testCoreRehydratesMainWindowSelectionFromSelectedConfiguration() {
    let core = Core()
    let configuration = KeyboardCowboyConfiguration(
      id: "config-1-id",
      name: "Config 1",
      userModes: [],
      groups: selectionGroups(),
    )

    core.contentStore.handle(.empty)
    core.configurationStore.updateConfigurations([configuration])
    core.contentStore.use(configuration)
    core.configSelection.publish([])
    core.groupSelection.publish([])
    core.workflowsSelection.publish([])

    core.rehydrateMainWindowSelection()

    XCTAssertEqual(core.configSelection.selections, ["config-1-id"])
    XCTAssertEqual(core.groupSelection.selections, ["group-1-id"])
    XCTAssertEqual(core.workflowsSelection.selections, ["workflow-1-id"])
    XCTAssertEqual(core.groupCoordinator.contentPublisher.data.map(\.id), ["workflow-1-id", "workflow-2-id"])
  }

  func testWindowFocusPreviousWindowIdsPreferMostRecentWindowPerScope() {
    WindowFocus.previousWindowIds = [:]

    WindowFocus.updatePreviousWindowIds(
      previousWindowId: 10,
      previousOwnerPid: 100,
      currentWindowId: 20,
      currentOwnerPid: 100,
      appWindowIds: [10, 20],
      stageWindowIds: [10, 20, 30],
      globalWindowIds: [10, 20, 30],
    )

    XCTAssertEqual(WindowFocus.previousWindowIds[.app], 10)
    XCTAssertEqual(WindowFocus.previousWindowIds[.stage], 10)
    XCTAssertEqual(WindowFocus.previousWindowIds[.global], 10)
  }

  func testWindowFocusPreviousWindowIdClearsInvalidAppScope() {
    WindowFocus.previousWindowIds = [.app: 10]

    WindowFocus.updatePreviousWindowIds(
      previousWindowId: 10,
      previousOwnerPid: 100,
      currentWindowId: 20,
      currentOwnerPid: 200,
      appWindowIds: [20, 30],
      stageWindowIds: [10, 20, 30],
      globalWindowIds: [10, 20, 30],
    )

    XCTAssertNil(WindowFocus.previousWindowIds[.app])
    XCTAssertEqual(WindowFocus.previousWindowIds[.stage], 10)
    XCTAssertEqual(WindowFocus.previousWindowIds[.global], 10)
  }

  func testWindowFocusPreferredPreviousWindowIdSkipsCurrentAndMissingWindows() {
    WindowFocus.previousWindowIds = [.global: 10, .stage: 20]

    XCTAssertNil(WindowFocus.preferredPreviousWindowId(in: [10, 20], ring: .stage, currentWindowId: 20))

    let preferredGlobal = WindowFocus.preferredPreviousWindowId(in: [20, 30], ring: .global, currentWindowId: 20)

    XCTAssertNil(preferredGlobal)
    XCTAssertNil(WindowFocus.previousWindowIds[.global])
  }

  func testWindowFocusPreviousWindowIdClearsInvalidStageAndGlobalScope() {
    WindowFocus.previousWindowIds = [.stage: 10, .global: 10]

    WindowFocus.updatePreviousWindowIds(
      previousWindowId: 10,
      previousOwnerPid: 100,
      currentWindowId: 20,
      currentOwnerPid: 100,
      appWindowIds: [10, 20],
      stageWindowIds: [20, 30],
      globalWindowIds: [20, 30],
    )

    XCTAssertEqual(WindowFocus.previousWindowIds[.app], 10)
    XCTAssertNil(WindowFocus.previousWindowIds[.stage])
    XCTAssertNil(WindowFocus.previousWindowIds[.global])
  }

  func testWindowFocusResetStateClearsCachedNavigationState() {
    WindowFocus.previousWindowIds = [.app: 10, .stage: 20, .global: 30]
    WindowFocus.pendingFocusWindowId = 42

    WindowFocus.resetState()

    XCTAssertTrue(WindowFocus.previousWindowIds.isEmpty)
    XCTAssertNil(WindowFocus.pendingFocusWindowId)
  }

  func testKeyboardCowboyAppDetectsUnitTests() {
    XCTAssertTrue(KeyboardCowboyApp.isRunningTests)
  }

  func testAppPreferencesUsesUnitTestConfigurationLocation() {
    XCTAssertEqual(AppPreferences.config.configLocation, .unitTests)
  }

  func testAppStorageContainerUsesDedicatedUnitTestDefaultsSuite() {
    let key = UUID().uuidString
    let value = UUID().uuidString

    AppStorageContainer.store.removeObject(forKey: key)
    UserDefaults.standard.removeObject(forKey: key)

    AppStorageContainer.store.set(value, forKey: key)

    XCTAssertEqual(AppStorageContainer.store.string(forKey: key), value)
    XCTAssertNil(UserDefaults.standard.string(forKey: key))

    AppStorageContainer.store.removeObject(forKey: key)
    UserDefaults.standard.removeObject(forKey: key)
  }

  // MARK: Private methods

  private func subject(_ id: String) -> (original: WorkflowGroup, copy: WorkflowGroup) {
    let group = WorkflowGroup.empty(id: id)
    return (original: group, copy: group)
  }

  private func selectionGroups() -> [WorkflowGroup] {
    [
      .init(id: "group-1-id", name: "group-1-name", workflows: [
        .init(id: "workflow-1-id", name: "workflow-1-name"),
        .init(id: "workflow-2-id", name: "workflow-2-name"),
      ]),
      .init(id: "group-2-id", name: "group-2-name", workflows: [
        .init(id: "workflow-3-id", name: "workflow-3-name"),
      ]),
    ]
  }

  private func context(_ groups: [WorkflowGroup] = []) -> (store: GroupStore,
                                                            selector: SelectionManager<GroupDetailViewModel>) {
    (store: GroupStore(groups), selector: SelectionManager())
  }
}
