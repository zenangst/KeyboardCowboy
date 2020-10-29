import ModelKit

public typealias ApplicationProvider = AnyStateController<[Application]>
public typealias CommandController = AnyActionController<CommandListView.Action>
public typealias GroupController = AnyViewController<[ModelKit.Group], GroupList.Action>
public typealias KeyboardShortcutController = AnyActionController<KeyboardShortcutListView.Action>
public typealias OpenPanelController = AnyViewController<String, OpenPanelAction>
public typealias SearchController = AnyViewController<ModelKit.SearchResults, SearchResultsList.Action>
public typealias WorkflowController = AnyViewController<Workflow?, WorkflowList.Action>
