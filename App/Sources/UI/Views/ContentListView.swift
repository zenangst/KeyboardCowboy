import SwiftUI

struct ContentDebounce: DebounceSnapshot {
  let workflows: Set<ContentViewModel.ID>
  let groups: Set<GroupViewModel.ID>
}

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

  @FocusState var isFocused: Bool
  private var focus: FocusState<AppFocus?>.Binding
  private let debounceSelectionManager: DebounceSelectionManager<ContentDebounce>
  private var focusPublisher: FocusPublisher<ContentViewModel>

  @Namespace var namespace

  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher

  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  private let groupSelectionManager: SelectionManager<GroupViewModel>

  @State var searchTerm: String = ""

  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       focusPublisher: FocusPublisher<ContentViewModel>,
       onAction: @escaping (Action) -> Void) {
    _contentSelectionManager = .init(initialValue: contentSelectionManager)
    self.groupSelectionManager = groupSelectionManager
    self.focusPublisher = focusPublisher
    self.focus = focus
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
            ForEach(publisher.data.filter(search).lazy, id: \.id) { element in
              ContentItemView(element, focusPublisher: focusPublisher, publisher: publisher,
                              contentSelectionManager: contentSelectionManager, onAction: onAction)
              .onTapGesture {
                contentSelectionManager.handleOnTap(publisher.data, element: element)
                focusPublisher.publish(element.id)
              }
              .contextMenu(menuItems: {
                contextualMenu(element.id)
              })
            }
            .focused($isFocused)
            .onChange(of: isFocused, perform: { newValue in
              guard newValue else { return }

              guard let lastSelection = contentSelectionManager.lastSelection else { return }

              withAnimation {
                proxy.scrollTo(lastSelection)
              }
            })
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              focus.wrappedValue = .detail(.name)
            })
            .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
              focus.wrappedValue = .groups
            })
            .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
              contentSelectionManager.publish(Set(publisher.data.map(\.id)))
            })
            .onMoveCommand(perform: { direction in
              if let elementID = contentSelectionManager.handle(
                direction,
                publisher.data.filter(search),
                proxy: proxy,
                vertical: true) {
                focusPublisher.publish(elementID)
              }
            })
            .onDeleteCommand {
              if contentSelectionManager.selections.count == publisher.data.count {
                withAnimation {
                  onAction(.removeWorkflows(contentSelectionManager.selections))
                }
              } else {
                onAction(.removeWorkflows(contentSelectionManager.selections))
              }
            }
          }
          .onChange(of: searchTerm, perform: { newValue in
            if !searchTerm.isEmpty {
              if let firstSelection = publisher.data.filter(search).first {
                contentSelectionManager.publish([firstSelection.id])
              } else {
                contentSelectionManager.publish([])
              }
            }
          })
          .padding(8)
          .onChange(of: contentSelectionManager.selections, perform: { newValue in
            debounceSelectionManager.process(.init(workflows: newValue, groups: groupSelectionManager.selections))
          })
          .onAppear {
            if let firstSelection = contentSelectionManager.selections.first {
              proxy.scrollTo(firstSelection)
            }
          }
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
    ContentListView($focus, contentSelectionManager: .init(), groupSelectionManager: .init(),
                    focusPublisher: .init()) { _ in }
      .designTime()
  }
}
