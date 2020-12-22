import ModelKit

public typealias ApplicationProvider = AnyStateController<[Application]>
public typealias CommandsController = AnyActionController<CommandListView.Action>
public typealias GroupsController = AnyActionController<GroupList.Action>
public typealias KeyboardShortcutsController = AnyActionController<KeyboardShortcutList.UIAction>
public typealias OpenPanelController = AnyViewController<String, OpenPanelAction>
public typealias SearchController = AnyViewController<ModelKit.SearchResults, SearchResultsList.Action>
public typealias WorkflowsController = AnyViewController<[Workflow], WorkflowList.Action>
public typealias WorkflowController = AnyViewController<Workflow, DetailView.Action>
