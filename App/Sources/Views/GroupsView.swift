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
    case moveWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case copyWorkflows(workflowIds: Set<ContentViewModel.ID>, groupId: GroupViewModel.ID)
    case removeGroups(Set<GroupViewModel.ID>)
  }

  @EnvironmentObject private var groupStore: GroupStore
  @EnvironmentObject private var publisher: GroupsPublisher
  @EnvironmentObject private var contentPublisher: ContentPublisher

  @ObservedObject var selectionManager: SelectionManager<GroupViewModel>
  private var focusPublisher = FocusPublisher<GroupViewModel>()

  var focus: FocusState<AppFocus?>.Binding
  @State private var confirmDelete: Confirm?
  @State private var dropDestination: Int?

  private let debounceSelectionManager: DebounceManager<GroupDebounce>
  private let moveManager: MoveManager<GroupViewModel> = .init()
  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       selectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    _selectionManager = .init(initialValue: selectionManager)
    self.onAction = onAction
    self.debounceSelectionManager = .init(.init(groups: selectionManager.selections), milliseconds: 100, onUpdate: { snapshot in
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
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach($publisher.data) { element in
            let group = element.wrappedValue
            GroupItemView(group, selectionManager: selectionManager, onAction: onAction)
              .contentShape(Rectangle())
              .overlay(content: { confirmDeleteView(group) })
              .padding(.vertical, 4)
              .padding(.horizontal, 8)
              .contextMenu(menuItems: {
                contextualMenu(for: group, onAction: onAction)
              })
              .onTapGesture {
                selectionManager.handleOnTap(publisher.data, element: element.wrappedValue)
                focusPublisher.publish(element.id)
              }
              .background(
                FocusView(focusPublisher, element: element,
                          selectionManager: selectionManager,
                          cornerRadius: 4, style: .list)
              )
              .draggable(element.wrappedValue.draggablePayload(prefix: "WG:", selections: selectionManager.selections))
              .dropDestination(for: String.self) { items, location in
                guard let (from, destination) = $publisher.data.moveOffsets(for: element, with: items.draggablePayload(prefix: "WG:")) else {
                  return false
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                  publisher.data.move(fromOffsets: IndexSet(from), toOffset: destination)
                }

                onAction(.moveGroups(source: from, destination: destination))
                return true
              }
              .tag(group)
          }
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
        .focused(focus, equals: .groups)
        .onReceive(selectionManager.$selections, perform: { newValue in
          confirmDelete = nil
          selectionManager.selectedColor = Color(nsColor: getColor())
          debounceSelectionManager.process(.init(groups: newValue))
        })
        .onAppear {
          if let firstSelection = selectionManager.selections.first {
            proxy.scrollTo(firstSelection)
          }
        }
      }

      AddButtonView("Add Group") {
        onAction(.openScene(.addGroup))
      }
      .font(.caption)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding([.leading, .bottom], 8)
      .debugEdit()
    }
  }

  private func getColor() -> NSColor {
    let color: NSColor
    if let groupId = selectionManager.selections.first,
       let group = publisher.data.first(where: { $0.id == groupId }),
       !group.color.isEmpty {
      color = .init(hex: group.color).blended(withFraction: 0.4, of: .black)!
    } else {
      color = .controlAccentColor
    }
    return color
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
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    GroupsView($focus, selectionManager: .init(), onAction: { _ in })
      .designTime()
  }
}

