import Inject
import SwiftUI
import UniformTypeIdentifiers

struct GroupsView: View {
  @ObserveInjection var inject

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
    case selectGroups([GroupViewModel.ID])
    case moveGroups(source: IndexSet, destination: Int)
    case removeGroups([GroupViewModel.ID])
  }
  @EnvironmentObject private var groupIds: GroupIdsPublisher
  @EnvironmentObject private var groupStore: GroupStore
  @EnvironmentObject private var publisher: GroupsPublisher
  @EnvironmentObject private var contentPublisher: ContentPublisher

  @State var dropCommands = Set<ContentViewModel>()
  @State private var dropOverlayIsVisible: Bool = false
  @State private var confirmDelete: Confirm?
  private let proxy: ScrollViewProxy?
  private let onAction: (Action) -> Void

  init(proxy: ScrollViewProxy? = nil,
       onAction: @escaping (Action) -> Void) {
    self.proxy = proxy
    self.onAction = onAction
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
      List(selection: $publisher.selections) {
        ForEach(publisher.data) { group in
          SidebarItemView(group, onAction: onAction)
            .listRowInsets(EdgeInsets(top: 0, leading: -2, bottom: 0, trailing: 4))
            .offset(x: 2)
            .contextMenu(menuItems: {
              contextualMenu(for: group, onAction: onAction)
            })
            .overlay(content: {
              HStack {
                Button(action: { confirmDelete = nil },
                       label: { Image(systemName: "x.circle") })
                .buttonStyle(.gradientStyle(config: .init(nsColor: .brown)))
                .keyboardShortcut(.escape)
                Text("Are you sure?")
                  .font(.footnote)
                Spacer()
                Button(action: {
                  confirmDelete = nil
                  onAction(.removeGroups(Array(publisher.selections)))
                }, label: { Image(systemName: "trash") })
                .buttonStyle(.destructiveStyle)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .padding(4)
              .background(Color(.windowBackgroundColor).cornerRadius(8))
              .opacity(confirmDelete?.contains(group.id) == true ? 1 : 0)
            })
            .tag(group)
        }
        .dropDestination(for: ContentViewModel.self) { items, index in
          // MARK: Note about .draggable & .dropDestination
          // For some unexplained reason, items is always a single item.
          // This means that the user can only drag a single item between containers (such as dragging a workflow to a different group).
          // Will investigate this further when we receive newer updates of macOS.
          let index = max(index-1,0)
          let group = groupStore.groups[index]
          let workflowIds = items.map(\.id)
          if NSEvent.modifierFlags.contains(.option) {
            groupStore.copy(workflowIds, to: group.id)
          } else {
            groupStore.move(workflowIds, to: group.id)
            if let first = workflowIds.first {
              contentPublisher.selections = [first]
            }
          }
          publisher.selections = [group.id]
        }
        .onMove { source, destination in
          onAction(.moveGroups(source: source, destination: destination))
        }
      }
      .onDeleteCommand(perform: {
        if publisher.data.count > 1 {
          confirmDelete = .multiple(ids: Array(publisher.selections))
        } else if let first = publisher.data.first {
          confirmDelete = .single(id: first.id)
        }
      })
      .onReceive(publisher.$selections, perform: { newValue in
        confirmDelete = nil
        groupIds.publish(.init(ids: Array(newValue)))
        onAction(.selectGroups(Array(newValue)))

        if let proxy, let first = newValue.first {
          proxy.scrollTo(first)
        }
      })
      .debugEdit()

      AddButtonView("Add Group") {
        onAction(.openScene(.addGroup))
      }
      .font(.caption)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .debugEdit()
    }
    .enableInjection()
  }

  private func emptyView() -> some View {
    VStack {
      HStack {
        AddButtonView("Add Group") {
          onAction(.openScene(.addGroup))
        }
        .frame(maxWidth: .infinity)
        .font(.headline)
      }

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
    GroupsView(onAction: { _ in })
      .designTime()
  }
}

private class WorkflowDropDelegate: DropDelegate {

  func dropEntered(info: DropInfo) {
    Swift.print("🐾 \(#file) - \(#function):\(#line)")
  }

  func dropExited(info: DropInfo) {
    Swift.print("🐾 \(#file) - \(#function):\(#line)")
  }

  func performDrop(info: DropInfo) -> Bool {
    Swift.print(info)
    return true
  }
}

