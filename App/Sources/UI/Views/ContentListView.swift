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

  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher
  private var focus: FocusState<AppFocus?>.Binding
  @Namespace private var namespace
  @State private var searchTerm: String = ""
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let debounceSelectionManager: DebounceSelectionManager<ContentDebounce>
  private let groupSelectionManager: SelectionManager<GroupViewModel>
  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
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
      ContentHeaderView(groupSelectionManager: groupSelectionManager,
                        namespace: namespace,
                        onAction: onAction)
      ContentListFilterView(focus,
                            contentSelectionManager: contentSelectionManager,
                            searchTerm: $searchTerm)
      ScrollViewReader { proxy in
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
              .focusable(focus, as: .workflow(element.id)) {
                contentSelectionManager.handleOnTap(publisher.data, element: element)
                debounceSelectionManager.process(.init(workflows: contentSelectionManager.selections,
                                                       groups: groupSelectionManager.selections))
              }
              .onAppear {
                if case .workflow = focus.wrappedValue, contentSelectionManager.selections.contains(element.id) {
                  focus.wrappedValue = .workflow(element.id)
                }
              }
            }
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              focus.wrappedValue = .detail(.name)
            })
            .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
              let id = groupSelectionManager.lastSelection ?? groupSelectionManager.selections.first ?? ""
              focus.wrappedValue = .group(id)
            })
            .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
              contentSelectionManager.publish(Set(publisher.data.map(\.id)))
            })
            .onMoveCommand(perform: { direction in
              if let elementID = contentSelectionManager.handle(
                direction,
                publisher.data.filter({ search($0) }),
                proxy: proxy,
                vertical: true) {
                focus.wrappedValue = .workflow(elementID)
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
                  focus.wrappedValue = .workflow(newId)
                }
              }
            }
          }
          .onAppear {
            DispatchQueue.main.async {
              let match = contentSelectionManager.lastSelection ?? contentSelectionManager.selections.first ?? ""
              proxy.scrollTo(match)
            }
          }
          .focusScope(namespace)
          .onChange(of: searchTerm, perform: { newValue in
            if !searchTerm.isEmpty {
              if let firstSelection = publisher.data.filter({ search($0) }).first {
                contentSelectionManager.publish([firstSelection.id])
              } else {
                contentSelectionManager.publish([])
              }
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
        focus.wrappedValue = .detail(.name)
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
