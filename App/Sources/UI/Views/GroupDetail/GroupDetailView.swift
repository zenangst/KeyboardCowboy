import Bonzai
import Carbon
import Inject
import SwiftUI

struct ContentDebounce: DebounceSnapshot {
  let workflows: Set<GroupDetailViewModel.ID>
}

@MainActor
struct GroupDetailView: View {
  enum Match {
    case unmatched
    case typeMatch(Kind)
    case match

    enum Kind: String, CaseIterable {
      case application = "app"
      case builtIn = "builtIn"
      case bundled = "bundled"
      case open = "open"
      case keyboard = "keyboard"
      case script = "script"
      case plain = "plain"
      case snippet = "snippet"
      case shortcut = "shortcut"
      case text = "text"
      case systemCommand = "system" 
      case menuBar = "menubar"
      case mouse = "mouse"
      case uiElement = "ui"
      case windowManagement = "window"
    }
  }

  enum Action: Hashable {
    case duplicate(workflowIds: Set<GroupDetailViewModel.ID>)
    case refresh(_ groupIds: Set<WorkflowGroup.ID>)
    case moveWorkflowsToGroup(_ groupId: WorkflowGroup.ID, workflows: Set<GroupDetailViewModel.ID>)
    case moveCommandsToWorkflow(_ workflowId: GroupDetailViewModel.ID, fromWorkflowId: GroupDetailViewModel.ID, commands: Set<CommandViewModel.ID>)
    case selectWorkflow(workflowIds: Set<GroupDetailViewModel.ID>)
    case removeWorkflows(Set<GroupDetailViewModel.ID>)
    case reorderWorkflows(source: IndexSet, destination: Int)
    case addWorkflow(workflowId: Workflow.ID)
  }

  @ObserveInjection var inject
  @FocusState var focus: LocalFocus<GroupDetailViewModel>?
  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: GroupDetailPublisher
  @Namespace private var namespace
  @State private var searchTerm: String = ""

  private let appFocus: FocusState<AppFocus?>.Binding
  private let workflowSelection: SelectionManager<GroupDetailViewModel>
  private let groupId: String
  private let debounce: DebounceController<ContentDebounce>
  private let onAction: (Action) -> Void

  init(_ appFocus: FocusState<AppFocus?>.Binding, groupId: String,
       workflowSelection: SelectionManager<GroupDetailViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.appFocus = appFocus
    self.workflowSelection = workflowSelection
    self.groupId = groupId
    self.onAction = onAction
    let initialDebounce = ContentDebounce(workflows: workflowSelection.selections)
    self.debounce = .init(initialDebounce, milliseconds: 150, onUpdate: { snapshot in
      onAction(.selectWorkflow(workflowIds: snapshot.workflows))
    })
  }

  private func search(_ workflow: GroupDetailViewModel) -> Bool {
    guard !searchTerm.isEmpty else { return true }

    var freetext = searchTerm.lowercased()
    let keywords = ["function", "fn", "command", "shift", "option", "control"]
    let enabledKeywords: [String] = keywords.compactMap {
      freetext = freetext.replacingFirstOccurrence(of: $0, with: "")
      return searchTerm.contains($0) ? $0 : nil
    }
    let searchTerms = enabledKeywords + (freetext
      .split(separator: " ")
      .map(String.init))
    var match: Match = .unmatched

    freetext = freetext.trimmingCharacters(in: .whitespacesAndNewlines)

    for searchTerm in searchTerms {
      switch workflow.trigger {
      case .application(let app):
        match = app.lowercased().contains(searchTerm) ? .typeMatch(.application) : .unmatched
      case .keyboard(let string):
        if searchTerm.contains("function") {
          match = string.contains(ModifierKey.function.pretty) ? .typeMatch(.keyboard) : .unmatched
        } else if searchTerm.contains("function") {
          match = string.contains(ModifierKey.function.pretty) ? .typeMatch(.keyboard) : .unmatched
        } else if searchTerm.contains("command") {
          match = string.contains(ModifierKey.leftCommand.pretty) ? .typeMatch(.keyboard) : .unmatched
        } else if searchTerm.contains("shift") {
          match = string.contains(ModifierKey.leftShift.pretty) ? .typeMatch(.keyboard) : .unmatched
        } else if searchTerm.contains("option") {
          match = string.contains(ModifierKey.leftOption.pretty) ? .typeMatch(.keyboard) : .unmatched
        } else if searchTerm.contains("control") {
          match = string.contains(ModifierKey.leftControl.pretty) ? .typeMatch(.keyboard) : .unmatched
        } else {
          match = string.lowercased().contains(searchTerm) ? .typeMatch(.keyboard) : .unmatched
        }
      case .snippet(let snippet):
        if enabledKeywords.contains(searchTerm) { continue }

        if snippet.lowercased().contains(searchTerm) {
          match = .typeMatch(.snippet)
        } else if searchTerm.contains("snippet ") {
          match = .typeMatch(.snippet)
        }
      default: continue
      }

      for image in workflow.images {
        switch image.kind {
        case .icon(let icon):
          if searchTerm.contains("app") && icon.path.contains("app") {
            match = .typeMatch(.application)
            break
          }
        default:
          if searchTerm.contains(image.kind.searchTerm) {
            match = .typeMatch(image.kind.match)
            freetext = freetext.replacingFirstOccurrence(of: image.kind.match.rawValue + " ", with: "")
          }
        }
      }

      if case .unmatched = match, workflow.name.lowercased().contains(freetext) {
        return freetext.count > 1 ? true : false
      }
    }

    var typeCheckMatches = searchTerms
      .filter { !enabledKeywords.contains($0) }

    if typeCheckMatches.isEmpty {
      typeCheckMatches = searchTerms
    }

    return switch match {
    case .unmatched: false
    case .typeMatch: typeCheckMatches.count == 1 ? true : false
    case .match: true
    }
  }

  @ViewBuilder
  var body: some View {
    ScrollViewReader { proxy in
      GroupDetailHeaderView()

      HStack {
        ZenLabel("Workflows", style: .content)
          .padding(.leading, 8)
          .frame(maxWidth: .infinity, alignment: .leading)

        if !publisher.data.isEmpty {
          GroupDetailAddButton(namespace, onAction: { onAction(.addWorkflow(workflowId: UUID().uuidString)) })
        }
      }

      WorkflowsFilterView(appFocus,
                          namespace: namespace,
                          onClear: {
        let match = workflowSelection.lastSelection ?? workflowSelection.selections.first ?? ""
        appFocus.wrappedValue = .workflows
        DispatchQueue.main.async {
          proxy.scrollTo(match)
        }
      }, onChange: { newValue in
        withAnimation(.smooth(duration: 0.2)) {
          searchTerm = newValue
        }
      })

      if groupsPublisher.data.isEmpty {
        Text("Add a group before adding a workflow.")
          .frame(maxWidth: .infinity)
          .padding()
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.systemGray))
      }

        if publisher.data.isEmpty {
          EmptyWorkflowList(namespace, onAction: onAction)
            .frame(maxHeight: .infinity)
            .toolbar(content: { toolbarContent() })
        } else {
          CompatList {
            let items = publisher.data.filter({ search($0) })
            ForEach(items.lazy, id: \.id) { element in
              WorkflowView(
                workflow: element,
                publisher: publisher,
                contentSelectionManager: workflowSelection,
                onAction: onAction
              )
              .modifier(LegacyOnTapFix(onTap: {
                focus = .element(element.id)
                onTap(element)
              }))
              .contextMenu(menuItems: {
                contextualMenu(element.id)
              })
              .focusable($focus, as: .element(element.id)) {
                if let keyCode = LocalEventMonitor.shared.event?.keyCode, keyCode == kVK_Tab,
                   let lastSelection = workflowSelection.lastSelection,
                   let match = publisher.data.first(where: { $0.id == lastSelection }) {
                  focus = .element(match.id)
                } else {
                  onTap(element)
                  proxy.scrollTo(element.id)
                }
              }
            }
            .dropDestination(for: GroupDetailViewModel.self, action: { collection, destination in
              var indexSet = IndexSet()
              for item in collection {
                guard let index = publisher.data.firstIndex(of: item) else { continue }
                indexSet.insert(index)
              }
              onAction(.reorderWorkflows(source: indexSet, destination: destination))
            })
            .compatContentListPadding()
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              appFocus.wrappedValue = .detail(.name)
            })
            .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
              if searchTerm.isEmpty {
                appFocus.wrappedValue = .groups
              } else {
                appFocus.wrappedValue = .search
              }
            })
            .onCommand(#selector(NSResponder.selectAll(_:)),
                       perform: {
              let newSelections = Set(publisher.data.map(\.id))
              workflowSelection.publish(newSelections)
              if let elementID = publisher.data.first?.id,
                 let lastSelection = workflowSelection.lastSelection {
                focus = .element(elementID)
                focus = .element(lastSelection)
              }
            })
            .onMoveCommand(perform: { direction in
              if let elementID = workflowSelection.handle(
                direction,
                publisher.data.filter({ search($0) }),
                proxy: proxy,
                vertical: true) {
                focus = .element(elementID)
              }
            })
            .onDeleteCommand {
              if workflowSelection.selections.count == publisher.data.count {
                withAnimation {
                  onAction(.removeWorkflows(workflowSelection.selections))
                }
              } else {
                onAction(.removeWorkflows(workflowSelection.selections))
                if let first = workflowSelection.selections.first {
                  let index = max(publisher.data.firstIndex(where: { $0.id == first }) ?? 0, 0)
                  let newId = publisher.data[index].id
                  focus = .element(newId)
                }
              }
            }

            Text("Results: \(items.count)")
              .font(.caption)
              .opacity(!searchTerm.isEmpty ? 1 : 0)
              .padding(.vertical, 8)
              .frame(maxWidth: .infinity)
              .frame(height: searchTerm.isEmpty ? 0 : nil)

            Color(.clear)
              .id("bottom")
              .padding(.bottom, 24)

          }
          .onChange(of: workflowSelection.selections) { newValue in
            let ids = Set(publisher.data.map(\.id))
            let newIds = Set(newValue)
            let result = ids.intersection(newIds)
            if !result.isEmpty, let first = result.first {
              proxy.scrollTo(first)
            }
          }
          .onAppear {
            guard let initialSelection = workflowSelection.initialSelection else { return }
            focus = .element(initialSelection)
            proxy.scrollTo(initialSelection)
          }
          .focused(appFocus, equals: .workflows)
          .onChange(of: searchTerm, perform: { newValue in
            if !searchTerm.isEmpty {
              if let firstSelection = publisher.data.filter({ search($0) }).first {
                workflowSelection.publish([firstSelection.id])
              } else {
                workflowSelection.publish([])
              }

              debounce.process(.init(workflows: workflowSelection.selections))
            }
          })
          .toolbar(content: { toolbarContent() })
          .onReceive(NotificationCenter.default.publisher(for: .newWorkflow), perform: { _ in
            proxy.scrollTo("bottom")
          })
        }
    }
    .padding(.horizontal, 2)
    .enableInjection()
  }

  private func toolbarContent() -> some ToolbarContent {
    ToolbarItemGroup(placement: .navigation) {
      Button(action: {
        searchTerm = ""
        onAction(.addWorkflow(workflowId: UUID().uuidString))
      },
             label: {
        Label(title: {
          Text("Add workflow")
        }, icon: {
          Image(systemName: "rectangle.stack.badge.plus")
            .renderingMode(.template)
            .foregroundColor(Color(.systemGray))
        })
      })
      .help("Add workflow")
    }
  }

  private func onTap(_ element: GroupDetailViewModel) {
    workflowSelection.handleOnTap(publisher.data, element: element)
    debounce.process(.init(workflows: workflowSelection.selections))
  }

  @ViewBuilder
  private func contextualMenu(_ selectedId: GroupDetailViewModel.ID) -> some View {
    Button("Duplicate", action: {
      if workflowSelection.selections.contains(selectedId) {
        onAction(.duplicate(workflowIds: workflowSelection.selections))
      } else {
        onAction(.duplicate(workflowIds: [selectedId]))
      }

      workflowSelection.publish([selectedId])
      workflowSelection.setLastSelection(selectedId)

      if workflowSelection.selections.count == 1 {
        appFocus.wrappedValue = .detail(.name)
      }
    })
    Menu("Move to") {
      // Show only other groups than the current one.
      // TODO: This is a bottle-neck for performance
      //      .filter({ !groupSelectionManager.selections.contains($0.id) })) { group in
      ForEach(groupsPublisher.data, id: \.self) { group in
        Button(group.name) {
          onAction(.moveWorkflowsToGroup(group.id, workflows: workflowSelection.selections))
        }
      }
    }
    Button("Delete", action: {
      onAction(.removeWorkflows(workflowSelection.selections))
    })
  }
}

struct WorkflowsView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    GroupDetailView($focus, groupId: UUID().uuidString, workflowSelection: .init()) { _ in }
      .designTime()
  }
}

fileprivate extension CommandViewModel.Kind {
  var match: GroupDetailView.Match.Kind {
    switch self {
    case .application: .application
    case .builtIn: .builtIn
    case .bundled: .bundled
    case .open: .open
    case .keyboard: .keyboard
    case .script: .script
    case .shortcut: .shortcut
    case .text: .text
    case .systemCommand: .systemCommand
    case .menuBar: .menuBar
    case .mouse: .mouse
    case .uiElement: .uiElement
    case .windowManagement: .windowManagement
    }
  }
}

fileprivate extension String {
  func replacingFirstOccurrence(of target: String, with replacement: String) -> String {
    guard let range = self.range(of: target) else {
      return self
    }

    return self.replacingCharacters(in: range, with: replacement)
  }
}
