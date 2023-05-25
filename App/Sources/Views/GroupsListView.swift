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

  @FocusState var isFocused: Bool
  private var focus: FocusState<AppFocus?>.Binding
  private var focusPublisher: FocusPublisher<GroupViewModel>
  private let namespace: Namespace.ID
  private let debounceSelectionManager: DebounceManager<GroupDebounce>
  private let moveManager: MoveManager<GroupViewModel> = .init()
  private let onAction: (GroupsView.Action) -> Void

  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>

  @EnvironmentObject private var publisher: GroupsPublisher
  @EnvironmentObject private var contentPublisher: ContentPublisher

  @State private var confirmDelete: Confirm?

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       focusPublisher: FocusPublisher<GroupViewModel>,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (GroupsView.Action) -> Void) {
    self.focus = focus
    self.namespace = namespace
    self.focusPublisher = focusPublisher
    _selectionManager = .init(initialValue: selectionManager)
    self.onAction = onAction
    self.debounceSelectionManager = .init(.init(groups: selectionManager.selections),
                                          milliseconds: 100,
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
            ForEach($publisher.data) { element in
              let group = element.wrappedValue
              GroupItemView(element,
                            focusPublisher: focusPublisher,
                            selectionManager: selectionManager,
                            onAction: onAction)
                .contentShape(Rectangle())
                .overlay(content: { confirmDeleteView(group) })
                .contextMenu(menuItems: {
                  contextualMenu(for: group, onAction: onAction)
                })
                .onTapGesture {
                  selectionManager.handleOnTap(publisher.data, element: element.wrappedValue)
                  focusPublisher.publish(element.id)
                }
                .tag(group)
            }
            .focused($isFocused)
            .onChange(of: isFocused, perform: { newValue in
              guard newValue else { return }

              guard let lastSelection = selectionManager.lastSelection else { return }

              withAnimation {
                proxy.scrollTo(lastSelection)
              }
            })
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              focus.wrappedValue = .workflows
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
                focusPublisher.publish(elementID)
              }
            })
            .onDeleteCommand {
              confirmDelete = .multiple(ids: Array(selectionManager.selections))
            }
          }
          .padding(8)
          .onReceive(selectionManager.$selections, perform: { newValue in
            confirmDelete = nil
            debounceSelectionManager.process(.init(groups: newValue))
          })
        }
      }
    }
  }

  func confirmDeleteView(_ group: GroupViewModel) -> some View {
    HStack {
      Button(action: { confirmDelete = nil },
             label: { Image(systemName: "x.circle") })
      .buttonStyle(.gradientStyle(config: .init(nsColor: .brown)))
      .keyboardShortcut(.cancelAction)
      Text("Are you sure?")
        .font(.footnote)
      Spacer()
      Button(action: {
        guard confirmDelete != nil else { return }
        confirmDelete = nil
        onAction(.removeGroups(selectionManager.selections))
      }, label: { Image(systemName: "trash") })
      .buttonStyle(.destructiveStyle)
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
                   focusPublisher: .init(),
                   selectionManager: .init(),
                   onAction: { _ in })
    .designTime()
  }
}
