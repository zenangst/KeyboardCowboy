import SwiftUI
import UniformTypeIdentifiers

struct GroupDebounce: DebounceSnapshot {
  let groups: Set<GroupViewModel.ID>
}

struct GroupsView: View {
  @Environment(\.controlActiveState) var controlActiveState

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

  enum Action {
    case openScene(AppScene)
    case selectGroups(Set<GroupViewModel.ID>)
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups(Set<GroupViewModel.ID>)
  }

  @EnvironmentObject private var groupStore: GroupStore
  @EnvironmentObject private var publisher: GroupsPublisher
  @EnvironmentObject private var contentPublisher: ContentPublisher

  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>

  @State private var confirmDelete: Confirm?

  @FocusState var focus: AppFocus?
  @Environment(\.resetFocus) var resetFocus

  private let debounceSelectionManager: DebounceManager<GroupDebounce>
  private let moveManager: MoveManager<GroupViewModel> = .init()
  private let onAction: (Action) -> Void

  init(selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    _selectionManager = .init(initialValue: selectionManager)
    self.onAction = onAction
    self.debounceSelectionManager = .init(.init(groups: selectionManager.selections), milliseconds: 150, onUpdate: { snapshot in
      onAction(.selectGroups(snapshot.groups))
    })
  }

  @ViewBuilder
  var body: some View {
    if !publisher.data.isEmpty {
      contentView()
    } else {
      emptyView()
    }
  }

  private func contentView() -> some View {
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        List(selection: $selectionManager.selections) {
          ForEach(publisher.data) { group in
            GroupItemView(group, selectionManager: selectionManager, onAction: onAction)
              .contentShape(Rectangle())
              .onTapGesture {
                focus = .groups
                selectionManager.handleOnTap(publisher.data, element: group)
              }
              .draggable(DraggableView.group([group]))
              .listRowInsets(EdgeInsets(top: 0, leading: -2, bottom: 0, trailing: 4))
              .overlay(content: { confirmDeleteView(group) })
              .offset(x: 2)
              .contextMenu(menuItems: {
                contextualMenu(for: group, onAction: onAction)
              })
              .tag(group)
              .listRowBackground(GroupBackgroundView(
                isFocused: $focus,
                selectionManager: selectionManager,
                group: group))
          }
          .dropDestination(for: DraggableView.self) { items, index in
            for item in items {
              switch item {
              case .group(let groups):
                let source = moveManager.onDropDestination(
                  groups, index: index,
                  data: publisher.data,
                  selections: selectionManager.selections)
                onAction(.moveGroups(source: source, destination: index))
              case .workflow(let workflows):
                // TODO: Should we move this to the coordinator?

                // MARK: Note about .draggable & .dropDestination
                // For some unexplained reason, items is always a single item.
                // This means that the user can only drag a single item between containers (such as dragging a workflow to a different group).
                // Will investigate this further when we receive newer updates of macOS.
                let index = max(index-1,0)
                let group = groupStore.groups[index]
                let workflowIds = Set(workflows.map(\.id))
                if NSEvent.modifierFlags.contains(.option) {
                  groupStore.copy(workflowIds, to: group.id)
                } else {
                  groupStore.move(workflowIds, to: group.id)
                }
                selectionManager.selections = [group.id]
              }
            }
          }
          .onMove { source, destination in
            onAction(.moveGroups(source: source, destination: destination))
          }
        }
        .onDeleteCommand(perform: {
          if publisher.data.count > 1 {
            confirmDelete = .multiple(ids: Array(selectionManager.selections))
          } else if let first = publisher.data.first {
            confirmDelete = .single(id: first.id)
          }
        })
        .onReceive(selectionManager.$selections, perform: { newValue in
          confirmDelete = nil
          debounceSelectionManager.process(.init(groups: newValue))
        })
        .focused($focus, equals: .groups)
        .onAppear {
          if let firstSelection = selectionManager.selections.first {
            proxy.scrollTo(firstSelection)
          }
        }
        .debugEdit()
      }

      AddButtonView("Add Group") {
        onAction(.openScene(.addGroup))
      }
      .font(.caption)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .debugEdit()
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
  func selectedBackground(_ group: GroupViewModel) -> some View {
    Group {
      if selectionManager.selections.contains(group.id) {
        Color(nsColor:
                focus == .groups
              ? .init(hex: group.color).blended(withFraction: 0.5, of: .black)!
              : .init(hex: group.color)
        )
      }
    }
    .cornerRadius(4, antialiased: true)
    .padding(.horizontal, 10)
    .grayscale(controlActiveState == .active ? 0.0 : 0.5)
    .opacity(focus == .groups ? 1.0 : 0.1)
  }

  private func emptyView() -> some View {
    VStack {
      Button(action: {
        withAnimation {
          onAction(.openScene(.addGroup))
        }
      }, label: {
        HStack(spacing: 8) {
          Image(systemName: "plus.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
          Divider()
            .opacity(0.5)
          Text("Add Group")
        }
        .padding(4)
      })
      .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen, hoverEffect: false)))
      .frame(maxHeight: 32)

      Text("No groups yet.\nAdd a group to get started.")
        .multilineTextAlignment(.center)
        .font(.footnote)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }

  private func overlayView() -> some View {
    VStack(spacing: 0) {
      LinearGradient(stops: [
        Gradient.Stop.init(color: .clear, location: 0),
        Gradient.Stop.init(color: .black.opacity(0.25), location: 0.25),
        Gradient.Stop.init(color: .black.opacity(0.75), location: 0.5),
        Gradient.Stop.init(color: .black.opacity(0.25), location: 0.75),
        Gradient.Stop.init(color: .clear, location: 1),
      ],
                     startPoint: .leading,
                     endPoint: .trailing)
      .frame(height: 1)
    }
    .allowsHitTesting(false)
    .shadow(color: Color(.black).opacity(0.25), radius: 2, x: 0, y: -2)
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

struct GroupsView_Provider: PreviewProvider {
  static var previews: some View {
    GroupsView(selectionManager: .init(), onAction: { _ in })
      .designTime()
  }
}
