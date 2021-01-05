import ModelKit
import SwiftUI

open class ViewKitStore: ObservableObject {
  @Published public var groups: [ModelKit.Group]
  public var selectedGroup: ModelKit.Group?
  public var selectedWorkflow: Workflow?
  public static let keyInputSubject = KeyInputSubjectWrapper()
  public var context: ViewKitFeatureContext!

  public init(groups: [ModelKit.Group] = [],
              context: ViewKitFeatureContext?) {
    self.groups = groups
    self.context = context
  }

  public static func preview() -> ViewKitStore {
    let groups = ModelFactory().groupList()
    let context = ViewKitFeatureContext.preview()
    return ViewKitStore(groups: groups, context: context)
  }
}

public class ViewKitFeatureContext {
  let keyInputSubjectWrapper: KeyInputSubjectWrapper

  public var applicationProvider: ApplicationProvider = ApplicationPreviewProvider().erase()
  public var commands: CommandsController = CommandPreviewController().erase()
  public var groups: GroupsController = GroupPreviewController().erase()
  public var keyboardsShortcuts = KeyboardShortcutPreviewController().erase()
  public var openPanel = OpenPanelPreviewController().erase()
  public var search: SearchController = SearchPreviewController().erase()
  public var workflow: WorkflowController = WorkflowPreviewController().erase()
  public var workflows: WorkflowsController = WorkflowsPreviewController().erase()

  public init(applicationProvider: ApplicationProvider,
              commands: CommandsController,
              groups: GroupsController,
              keyInputSubjectWrapper: KeyInputSubjectWrapper,
              keyboardsShortcuts: KeyboardShortcutsController,
              openPanel: OpenPanelController,
              search: SearchController,
              workflow: WorkflowController,
              workflows: WorkflowsController
  ) {
    self.applicationProvider = applicationProvider
    self.commands = commands
    self.groups = groups
    self.keyInputSubjectWrapper = keyInputSubjectWrapper
    self.keyboardsShortcuts = keyboardsShortcuts
    self.openPanel = openPanel
    self.search = search
    self.workflow = workflow
    self.workflows = workflows
  }

  public static func preview() -> ViewKitFeatureContext {
    ViewKitFeatureContext(applicationProvider: ApplicationPreviewProvider().erase(),
                          commands: CommandPreviewController().erase(),
                          groups: GroupPreviewController().erase(),
                          keyInputSubjectWrapper: KeyInputSubjectWrapper(),
                          keyboardsShortcuts: KeyboardShortcutPreviewController().erase(),
                          openPanel: OpenPanelPreviewController().erase(),
                          search: SearchPreviewController().erase(),
                          workflow: WorkflowPreviewController().erase(),
                          workflows: WorkflowsPreviewController().erase())
  }
}
