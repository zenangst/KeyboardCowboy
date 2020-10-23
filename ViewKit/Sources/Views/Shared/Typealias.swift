import ModelKit

public typealias ApplicationProvider = AnyStateController<[Application]>
public typealias CommandController = AnyViewController<[Command], CommandListView.Action>
public typealias GroupController = AnyViewController<[ModelKit.Group], GroupList.Action>
public typealias KeyboardShortcutController = AnyViewController<[ModelKit.KeyboardShortcut],
                                                                KeyboardShortcutListView.Action>
public typealias OpenPanelController = AnyViewController<String, OpenPanelAction>
public typealias SearchController = AnyViewController<ModelKit.SearchResults, SearchResultsList.Action>
public typealias WorkflowController = AnyViewController<Workflow?, WorkflowList.Action>
