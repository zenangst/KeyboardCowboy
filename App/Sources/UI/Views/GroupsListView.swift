import SwiftUI

struct GroupsListView: View {
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

  @EnvironmentObject private var publisher: GroupsPublisher
  @State private var confirmDelete: Confirm?
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let debounceSelectionManager: DebounceSelectionManager<GroupDebounce>
  private let moveManager: MoveManager<GroupViewModel> = .init()
  private let namespace: Namespace.ID
  private let onAction: (GroupsView.Action) -> Void
  private let selectionManager: SelectionManager<GroupViewModel>
  private var focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       selectionManager: SelectionManager<GroupViewModel>,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (GroupsView.Action) -> Void) {
    self.focus = focus
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
                selectionManager: selectionManager,
                onAction: onAction
              )
              .contentShape(Rectangle())
              .overlay(content: { confirmDeleteView(group) })
              .contextMenu(menuItems: {
                contextualMenu(for: group, onAction: onAction)
              })
              .focusable(focus, as: .group(group.id)) {
                selectionManager.handleOnTap(publisher.data, element: group)
                confirmDelete = nil
                debounceSelectionManager.process(.init(groups: selectionManager.selections))
                guard let first = contentSelectionManager.selections.first else { return }
                focus.wrappedValue = .workflow(first)
              }
            }
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              let first = contentSelectionManager.selections.first ?? ""
              focus.wrappedValue = .workflow(contentSelectionManager.lastSelection ?? first)
            })
            .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: { })
            .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
              selectionManager.selections = Set(publisher.data.map(\.id))
            })
            .onMoveCommand(perform: { direction in
              if let elementID = selectionManager.handle(
                direction,
                publisher.data,
                proxy: proxy,
                vertical: true) {
                focus.wrappedValue = .group(elementID)
              }
            })
            .onDeleteCommand {
              confirmDelete = .multiple(ids: Array(selectionManager.selections))
            }
          }
          .onAppear {
            DispatchQueue.main.async {
              let match = selectionManager.lastSelection ?? selectionManager.selections.first ?? ""
              proxy.scrollTo(match)
            }
          }
          .padding(.horizontal, 8)
        }
      }
    }
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
                              onAction: @escaping (GroupsView.Action) -> Void) -> some View {
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
