import Carbon
import SwiftUI

struct ContentDebounce: DebounceSnapshot {
  let workflows: Set<ContentViewModel.ID>
  let groups: Set<GroupViewModel.ID>
}

@MainActor
struct ContentListView: View {
  enum Action: Hashable {
    case duplicate(workflowIds: Set<ContentViewModel.ID>)
    case refresh(_ groupIds: Set<WorkflowGroup.ID>)
    case moveWorkflowsToGroup(_ groupId: WorkflowGroup.ID, workflows: Set<ContentViewModel.ID>)
    case selectWorkflow(workflowIds: Set<ContentViewModel.ID>, groupIds: Set<WorkflowGroup.ID>)
    case removeWorkflows(Set<ContentViewModel.ID>)
    case reorderWorkflows(source: IndexSet, destination: Int)
    case addWorkflow(workflowId: Workflow.ID)
  }

  @FocusState var focus: LocalFocus<ContentViewModel>?
  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher
  private var appFocus: FocusState<AppFocus?>.Binding
  @Namespace private var namespace
  @State private var searchTerm: String = ""
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let debounceSelectionManager: DebounceSelectionManager<ContentDebounce>
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let onAction: (Action) -> Void

  init(_ appFocus: FocusState<AppFocus?>.Binding,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.appFocus = appFocus
    self.contentSelectionManager = contentSelectionManager
    self.groupSelectionManager = groupSelectionManager
    self.onAction = onAction
    let initialDebounce = ContentDebounce(workflows: contentSelectionManager.selections,
                                          groups: groupSelectionManager.selections)
    self.debounceSelectionManager = .init(initialDebounce, milliseconds: 100, onUpdate: { snapshot in
      onAction(.selectWorkflow(workflowIds: snapshot.workflows, groupIds: snapshot.groups))
    })
  }

  private func search(_ workflow: ContentViewModel) -> Bool {
    guard !searchTerm.isEmpty else { return true }
    if workflow.name.lowercased().contains(searchTerm.lowercased()) {
      return true
    }
    return false
  }

  @ViewBuilder
  var body: some View {
    if groupsPublisher.data.isEmpty || publisher.data.isEmpty {
      ContentListEmptyView(namespace, onAction: onAction)
        .fixedSize()
    } else {
      ScrollViewReader { proxy in
        ContentHeaderView(groupSelectionManager: groupSelectionManager,
                          namespace: namespace,
                          onAction: onAction)
        ContentListFilterView(appFocus, searchTerm: $searchTerm) {
          let match = contentSelectionManager.lastSelection ?? contentSelectionManager.selections.first ?? ""
          appFocus.wrappedValue = .workflows
          DispatchQueue.main.async {
            proxy.scrollTo(match)
          }
        }
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(publisher.data.filter({ search($0) }), id: \.id) { element in
              ContentItemView(
                workflow: element,
                publisher: publisher,
                contentSelectionManager: contentSelectionManager,
                onAction: onAction
              )
              .contentShape(Rectangle())
              .contextMenu(menuItems: {
                contextualMenu(element.id)
              })
              .focusable($focus, as: .element(element.id)) {
                if let keyCode = LocalEventMonitor.shared.event?.keyCode, keyCode == kVK_Tab,
                   let lastSelection = contentSelectionManager.lastSelection,
                   let match = publisher.data.first(where: { $0.id == lastSelection }) {
                  focus = .element(match.id)
                } else {
                  contentSelectionManager.handleOnTap(publisher.data, element: element)
                  debounceSelectionManager.process(.init(workflows: contentSelectionManager.selections,
                                                         groups: groupSelectionManager.selections))
                  proxy.scrollTo(element.id)
                }
              }
            }
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
              contentSelectionManager.publish(newSelections)
              if let elementID = publisher.data.first?.id,
                 let lastSelection = contentSelectionManager.lastSelection {
                focus = .element(elementID)
                focus = .element(lastSelection)
                onAction(
                  .selectWorkflow(
                    workflowIds: contentSelectionManager.selections,
                    groupIds: groupSelectionManager.selections
                  )
                )
              }
            })
            .onMoveCommand(perform: { direction in
              if let elementID = contentSelectionManager.handle(
                direction,
                publisher.data.filter({ search($0) }),
                proxy: proxy,
                vertical: true) {
                focus = .element(elementID)
              }
            })
            .onDeleteCommand {
              if contentSelectionManager.selections.count == publisher.data.count {
                withAnimation {
                  onAction(.removeWorkflows(contentSelectionManager.selections))
                }
              } else {
                onAction(.removeWorkflows(contentSelectionManager.selections))
                if let first = contentSelectionManager.selections.first {
                  let index = max(publisher.data.firstIndex(where: { $0.id == first }) ?? 0, 0)
                  let newId = publisher.data[index].id
                  focus = .element(newId)
                }
              }
            }
            Color(.clear)
              .id("bottom")
              .padding(.bottom, 48)
          }
          .onAppear {
            DispatchQueue.main.async {
              let match = contentSelectionManager.lastSelection ?? contentSelectionManager.selections.first ?? ""
              proxy.scrollTo(match)
            }
          }
          .focusSection()
          .focused(appFocus, equals: .workflows)
          .onChange(of: searchTerm, perform: { newValue in
            if !searchTerm.isEmpty {
              if let firstSelection = publisher.data.filter({ search($0) }).first {
                contentSelectionManager.publish([firstSelection.id])
              } else {
                contentSelectionManager.publish([])
              }

              debounceSelectionManager.process(.init(workflows: contentSelectionManager.selections,
                                                     groups: groupSelectionManager.selections))
            }
          })
          .padding(8)
          .toolbar {
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
              .opacity(publisher.data.isEmpty ? 0 : 1)
              .help("Add workflow")
            }
          }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newWorkflow), perform: { _ in
          proxy.scrollTo("bottom")
        })
      }
    }
  }

  @ViewBuilder
  private func contextualMenu(_ selectedId: ContentViewModel.ID) -> some View {
    Button("Duplicate", action: {
      if contentSelectionManager.selections.contains(selectedId) {
        onAction(.duplicate(workflowIds: contentSelectionManager.selections))
      } else {
        onAction(.duplicate(workflowIds: [selectedId]))
        contentSelectionManager.selections = [selectedId]
        contentSelectionManager.setLastSelection(selectedId)
      }

      if contentSelectionManager.selections.count == 1 {
        appFocus.wrappedValue = .detail(.name)
      }
    })
    Menu("Move to") {
      // Show only other groups than the current one.
      // TODO: This is a bottle-neck for performance
//      .filter({ !groupSelectionManager.selections.contains($0.id) })) { group in
      ForEach(groupsPublisher.data, id: \.self) { group in
        Button(group.name) {
          onAction(.moveWorkflowsToGroup(group.id, workflows: contentSelectionManager.selections))
        }
      }
    }
    Button("Delete", action: {
      onAction(.removeWorkflows(contentSelectionManager.selections))
    })
  }
}

struct ContentListView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    ContentListView(
      $focus,
      contentSelectionManager: .init(),
      groupSelectionManager: .init()
    ) { _ in }
      .designTime()
  }
}
