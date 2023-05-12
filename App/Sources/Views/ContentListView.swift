import SwiftUI

struct ContentListView: View {
  private var focus: FocusState<AppFocus?>.Binding
  private let debounceSelectionManager: DebounceManager<ContentDebounce>
  private var focusPublisher: FocusPublisher<ContentViewModel>

  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher

  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @ObservedObject private var groupSelectionManager: SelectionManager<GroupViewModel>

  private let onAction: (ContentView.Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       focusPublisher: FocusPublisher<ContentViewModel>,
       onAction: @escaping (ContentView.Action) -> Void) {
    _contentSelectionManager = .init(initialValue: contentSelectionManager)
    _groupSelectionManager = .init(initialValue: groupSelectionManager)
    self.focusPublisher = focusPublisher
    self.focus = focus
    self.onAction = onAction
    let initialDebounce = ContentDebounce(workflows: contentSelectionManager.selections,
                                          groups: groupSelectionManager.selections)
    self.debounceSelectionManager = .init(initialDebounce, milliseconds: 100, onUpdate: { snapshot in
      onAction(.selectWorkflow(workflowIds: snapshot.workflows, groupIds: snapshot.groups))
    })
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        if groupsPublisher.data.isEmpty || publisher.data.isEmpty {
          ContentListEmptyView(onAction: onAction)
        } else {
          LazyVStack(spacing: 0) {
            ForEach($publisher.data) { element in
              ContentItemView(element.wrappedValue)
                .padding(4)
                .background(
                  FocusView(focusPublisher, element: element, selectionManager: contentSelectionManager,
                            cornerRadius: 4, style: .list)
                )
                .grayscale(element.wrappedValue.isEnabled ? 0 : 0.5)
                .opacity(element.wrappedValue.isEnabled ? 1 : 0.5)
                .onTapGesture {
                  contentSelectionManager.handleOnTap(publisher.data, element: element.wrappedValue)
                  focusPublisher.publish(element.id)
                }
                .contextMenu(menuItems: {
                  contextualMenu()
                })
                .draggable(element.wrappedValue.draggablePayload(prefix: "W:", selections: contentSelectionManager.selections))
                .dropDestination(for: String.self) { items, location in
                  guard let (from, destination) = $publisher.data.moveOffsets(for: element, with: items.draggablePayload(prefix: "W:")) else {
                    return false
                  }
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                    publisher.data.move(fromOffsets: IndexSet(from), toOffset: destination)
                  }
                  onAction(.moveWorkflows(source: from, destination: destination))
                  return true
                } isTargeted: { _ in }
            }
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              focus.wrappedValue = .detail(.name)
            })
            .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
              focus.wrappedValue = .groups
            })
            .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
              contentSelectionManager.selections = Set(publisher.data.map(\.id))
            })
            .onMoveCommand(perform: { direction in
              if let elementID = contentSelectionManager.handle(
                direction,
                publisher.data,
                proxy: proxy,
                vertical: true) {
                focusPublisher.publish(elementID)
              }
            })
            .onDeleteCommand {
              onAction(.removeWorflows(contentSelectionManager.selections))
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
          .onChange(of: contentSelectionManager.selections, perform: { newValue in
            contentSelectionManager.selectedColor = Color(nsColor: getColor())
            debounceSelectionManager.process(.init(workflows: newValue, groups: groupSelectionManager.selections))
          })
          .onAppear {
            if let firstSelection = contentSelectionManager.selections.first {
              proxy.scrollTo(firstSelection)
            }
            contentSelectionManager.selectedColor = Color(nsColor: getColor())
          }
          .toolbar {
            ToolbarItemGroup(placement: .navigation) {
              if !groupsPublisher.data.isEmpty {
                Button(action: {
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
              }
            }
          }
        }
      }
    }
  }

  private func getColor() -> NSColor {
    let color: NSColor
    if let groupId = groupSelectionManager.selections.first,
       let group = groupsPublisher.data.first(where: { $0.id == groupId }),
       !group.color.isEmpty {
      color = .init(hex: group.color).blended(withFraction: 0.4, of: .black)!
    } else {
      color = .controlAccentColor
    }
    return color
  }

  @ViewBuilder
  private func contextualMenu() -> some View {
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
      onAction(.removeWorflows(contentSelectionManager.selections))
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
