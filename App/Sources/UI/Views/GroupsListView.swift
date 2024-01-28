import Carbon
import SwiftUI

struct GroupDebounce: DebounceSnapshot {
  let groups: Set<GroupViewModel.ID>
}

struct GroupsListView: View {
  enum Action {
    case openScene(AppScene)
    case selectGroups(Set<GroupViewModel.ID>)
    case moveGroups(source: IndexSet, destination: Int)
    case moveWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case copyWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case removeGroups(Set<GroupViewModel.ID>)
  }

  enum Confirm {
    case single(id: GroupViewModel.ID)
    case multiple(ids: [GroupViewModel.ID])

    func contains(_ id: GroupViewModel.ID) -> Bool {
      switch self {
      case .single(let groupId):
        return groupId == id
      case .multiple(let ids):
        return ids.contains(id) && ids.first == id
      }
    }
  }

  @FocusState var focus: LocalFocus<GroupViewModel>?
  @EnvironmentObject private var publisher: GroupsPublisher
  @State private var confirmDelete: Confirm?
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let debounceSelectionManager: DebounceSelectionManager<GroupDebounce>
  private let namespace: Namespace.ID
  private let onAction: (GroupsListView.Action) -> Void
  private let selectionManager: SelectionManager<GroupViewModel>
  private var appFocus: FocusState<AppFocus?>.Binding

  init(_ appFocus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       selectionManager: SelectionManager<GroupViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (GroupsListView.Action) -> Void) {
    self.appFocus = appFocus
    self.namespace = namespace
    self.selectionManager = selectionManager
    self.contentSelectionManager = contentSelectionManager
    self.onAction = onAction
    self.debounceSelectionManager = .init(.init(groups: selectionManager.selections),
                                          milliseconds: 150,
                                          onUpdate: { snapshot in
      onAction(.selectGroups(snapshot.groups))
    })
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if publisher.data.isEmpty {
          GroupsEmptyListView(namespace, onAction: onAction)
        } else {
          LazyVStack(spacing: 0) {
            ForEach(publisher.data.lazy, id: \.id) { group in
              GroupItemView(
                group,
                groupsPublisher: publisher,
                selectionManager: selectionManager,
                onAction: onAction
              )
              .contentShape(Rectangle())
              .dropDestination(SidebarListDropItem.self, color: .accentColor, onDrop: { items, location in
                for item in items {
                  switch item {
                  case .group:
                    let ids = Array(selectionManager.selections)
                    guard let (from, destination) = publisher.data.moveOffsets(for: group, with: ids) else {
                      return false
                    }

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                      publisher.data.move(fromOffsets: IndexSet(from), toOffset: destination)
                    }

                    onAction(.moveGroups(source: from, destination: destination))
                  case .workflow:
                    onAction(.moveWorkflows(workflowIds: contentSelectionManager.selections, groupId: group.id))
                  }
                }
                return true
              })
              .overlay(content: { confirmDeleteView(group) })
              .contextMenu(menuItems: {
                contextualMenu(for: group, onAction: onAction)
              })
              .focusable($focus, as: .element(group.id)) {
                if let keyCode = LocalEventMonitor.shared.event?.keyCode, keyCode == kVK_Tab,
                   let lastSelection = selectionManager.lastSelection,
                   let match = publisher.data.first(where: { $0.id == lastSelection }) {
                  focus = .element(match.id)
                } else {
                  onTap(group)
                }
              }
              .gesture(
                TapGesture(count: 1)
                  .onEnded { _ in
                    onTap(group)
                  }
                  .simultaneously(with: TapGesture(count: 2)
                    .onEnded { _ in
                      onAction(.openScene(.editGroup(group.id)))
                    })
              )
            }
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              appFocus.wrappedValue = .workflows
            })
            .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {})
            .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
              selectionManager.selections = Set(publisher.data.map(\.id))
            })
            .onMoveCommand(perform: { direction in
              if let elementID = selectionManager.handle(
                direction,
                publisher.data,
                proxy: proxy,
                vertical: true) {
                focus = .element(elementID)
              }
            })
            .onDeleteCommand {
              confirmDelete = .multiple(ids: Array(selectionManager.selections))
            }
          }
          .onAppear {
            let match = selectionManager.lastSelection ?? selectionManager.selections.first ?? ""
            focus = .element(match)
            DispatchQueue.main.async {
              proxy.scrollTo(match)
            }
          }
          .focusSection()
          .focused(appFocus, equals: .groups)
          .padding(.horizontal, 8)
        }
      }
    }
  }

  private func onTap(_ element: GroupViewModel) {
    selectionManager.handleOnTap(publisher.data, element: element)
    confirmDelete = nil
    debounceSelectionManager.process(.init(groups: selectionManager.selections))
  }

  func confirmDeleteView(_ group: GroupViewModel) -> some View {
    HStack {
      Button(action: { confirmDelete = nil },
             label: { Image(systemName: "x.circle") })
      .buttonStyle(.calm(color: .systemBrown, padding: .medium))
      .keyboardShortcut(.cancelAction)
      Text("Are you sure?")
        .font(.footnote)
      Spacer()
      Button(action: {
        guard confirmDelete != nil else { return }
        confirmDelete = nil
        onAction(.removeGroups(selectionManager.selections))
      }, label: { Image(systemName: "trash") })
      .buttonStyle(.calm(color: .systemRed, padding: .medium))
      .keyboardShortcut(.defaultAction)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor).cornerRadius(4))
    .opacity(confirmDelete?.contains(group.id) == true ? 1 : 0)
    .padding(2)
  }

  @ViewBuilder
  private func contextualMenu(for group: GroupViewModel,
                              onAction: @escaping (GroupsListView.Action) -> Void) -> some View {
    Button("Edit", action: { onAction(.openScene(.editGroup(group.id))) })
    Divider()
    Button("Remove", action: {
      onAction(.removeGroups([group.id]))
    })
  }
}

struct GroupsListView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  @Namespace static var namespace
  static var previews: some View {
    GroupsListView($focus,
                   namespace: namespace,
                   selectionManager: .init(),
                   contentSelectionManager: .init(),
                   onAction: { _ in })
    .designTime()
  }
}
