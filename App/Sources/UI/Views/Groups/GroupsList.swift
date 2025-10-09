import Bonzai
import Carbon
import SwiftUI

struct GroupDebounce: DebounceSnapshot {
  let groups: Set<GroupViewModel.ID>
}

struct GroupsList: View {
  enum Action {
    case openScene(AppScene)
    case selectGroups(Set<GroupViewModel.ID>)
    case moveGroups(source: IndexSet, destination: Int)
    case moveWorkflows(workflowIds: Set<GroupDetailViewModel.ID>, groupId: GroupViewModel.ID)
    case copyWorkflows(workflowIds: Set<GroupDetailViewModel.ID>, groupId: GroupViewModel.ID)
    case removeGroups(Set<GroupViewModel.ID>)
  }

  enum Confirm {
    case single(id: GroupViewModel.ID)
    case multiple(ids: [GroupViewModel.ID])

    func contains(_ id: GroupViewModel.ID) -> Bool {
      switch self {
      case let .single(groupId):
        groupId == id
      case let .multiple(ids):
        ids.contains(id) && ids.first == id
      }
    }
  }

  @FocusState var focus: LocalFocus<GroupViewModel>?
  @EnvironmentObject private var publisher: GroupsPublisher
  @State private var confirmDelete: Confirm?
  @State private var reorderId: UUID = .init()
  private let workflowSelection: SelectionManager<GroupDetailViewModel>
  private let debounce: DebounceController<GroupDebounce>
  private let namespace: Namespace.ID
  private let onAction: (GroupsList.Action) -> Void
  private let groupSelection: SelectionManager<GroupViewModel>
  private var appFocus: FocusState<AppFocus?>.Binding

  init(_ appFocus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       groupSelection: SelectionManager<GroupViewModel>,
       workflowSelection: SelectionManager<GroupDetailViewModel>,
       onAction: @escaping (GroupsList.Action) -> Void)
  {
    self.appFocus = appFocus
    self.namespace = namespace
    self.groupSelection = groupSelection
    self.workflowSelection = workflowSelection
    self.onAction = onAction
    debounce = .init(.init(groups: groupSelection.selections),
                     milliseconds: 150,
                     onUpdate: { snapshot in
                       onAction(.selectGroups(snapshot.groups))
                     })
  }

  var body: some View {
    ScrollViewReader { proxy in
      if publisher.data.isEmpty {
        EmptyGroupsList(namespace, isVisible: .readonly { publisher.data.isEmpty }, onAction: onAction)
      } else {
        CompatList {
          ForEach(publisher.data.lazy, id: \.id) { group in
            GroupListItem(group, selectionManager: groupSelection, onAction: onAction)
              .overlay(content: { confirmDeleteView(group) })
              .modifier(LegacyOnTapFix(onTap: {
                focus = .element(group.id)
                onTap(group)
              }))
              .contextMenu(menuItems: {
                contextualMenu(for: group, onAction: onAction)
              })
              .focusable($focus, as: .element(group.id)) {
                if let keyCode = LocalEventMonitor.shared.event?.keyCode, keyCode == kVK_Tab,
                   let lastSelection = groupSelection.lastSelection,
                   let match = publisher.data.first(where: { $0.id == lastSelection })
                {
                  focus = .element(match.id)
                } else {
                  onTap(group)
                  proxy.scrollTo(group.id)
                }
              }
              .gesture(
                TapGesture(count: 1)
                  .onEnded { _ in
                    focus = .element(group.id)
                  }
                  .simultaneously(with: TapGesture(count: 2)
                    .onEnded { _ in
                      onAction(.openScene(.editGroup(group.id)))
                    }),
              )
          }
          .dropDestination(for: GroupViewModel.self, action: { collection, destination in
            var indexSet = IndexSet()
            for item in collection {
              guard let index = publisher.data.firstIndex(of: item) else { continue }

              indexSet.insert(index)
            }
            onAction(.moveGroups(source: indexSet, destination: destination))
            reorderId = UUID()
          })
          .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
            appFocus.wrappedValue = .workflows
          })
          .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {})
          .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
            groupSelection.publish(Set(publisher.data.map(\.id)))
          })
          .onMoveCommand(perform: { direction in
            if let elementID = groupSelection.handle(
              direction,
              publisher.data,
              proxy: proxy,
              vertical: true,
            ) {
              focus = .element(elementID)
            }
          })
          .onDeleteCommand {
            confirmDelete = .multiple(ids: Array(groupSelection.selections))
          }
          .id(reorderId)
        }
        .onAppear {
          guard let initialSelection = groupSelection.initialSelection else { return }

          focus = .element(initialSelection)
          proxy.scrollTo(initialSelection)
        }
        .focused(appFocus, equals: .groups)
        .opacity(!publisher.data.isEmpty ? 1 : 0)
        .frame(height: !publisher.data.isEmpty ? nil : 0)
      }
    }
  }

  private func onTap(_ element: GroupViewModel) {
    groupSelection.handleOnTap(publisher.data, element: element)
    confirmDelete = nil
    debounce.process(.init(groups: groupSelection.selections))
  }

  func confirmDeleteView(_ group: GroupViewModel) -> some View {
    HStack {
      Button(action: { confirmDelete = nil },
             label: { Image(systemName: "x.circle") })
        .keyboardShortcut(.cancelAction)
        .environment(\.buttonBackgroundColor, .systemBrown)

      Text("Are you sure?")
        .font(.footnote)
      Spacer()
      Button(action: {
        guard confirmDelete != nil else { return }

        confirmDelete = nil
        onAction(.removeGroups(groupSelection.selections))
      }, label: { Image(systemName: "trash") })
        .environment(\.buttonBackgroundColor, .systemRed)
        .keyboardShortcut(.defaultAction)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor).cornerRadius(4))
    .opacity(confirmDelete?.contains(group.id) == true ? 1 : 0)
    .padding(2)
  }

  @ViewBuilder
  private func contextualMenu(for group: GroupViewModel,
                              onAction: @escaping (GroupsList.Action) -> Void) -> some View
  {
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
    GroupsList($focus,
               namespace: namespace,
               groupSelection: .init(),
               workflowSelection: .init(),
               onAction: { _ in })
      .designTime()
  }
}
