import SwiftUI

struct ContentListView: View {
  @FocusState var isFocused: Bool
  private var focus: FocusState<AppFocus?>.Binding
  private let debounceSelectionManager: DebounceSelectionManager<ContentDebounce>
  private var focusPublisher: FocusPublisher<ContentViewModel>

  @Namespace var namespace

  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher

  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @ObservedObject private var groupSelectionManager: SelectionManager<GroupViewModel>

  @State var searchTerm: String = ""

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

  private func search(_ workflow: Binding<ContentViewModel>) -> Bool {
    guard !searchTerm.isEmpty else { return true }
    if workflow.wrappedValue.name.lowercased().hasPrefix(searchTerm.lowercased()) {
      return true
    } else if workflow.wrappedValue.name.contains(searchTerm) {
      return true
    }
    return false
  }

  @ViewBuilder
  var body: some View {
    if !publisher.data.isEmpty {
      HStack(spacing: 8) {
        Image(systemName: searchTerm.isEmpty
              ? "line.3.horizontal.decrease.circle"
              : "line.3.horizontal.decrease.circle.fill")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundColor(contentSelectionManager.selectedColor)
        .frame(width: 12)
        .padding(.leading, 8)
        TextField("Filter", text: $searchTerm)
          .textFieldStyle(AppTextFieldStyle(.caption2,
                                            unfocusedOpacity: 0,
                                            color: contentSelectionManager.selectedColor))
          .focused(focus, equals: .search)
          .onExitCommand(perform: {
            searchTerm = ""
          })
          .onSubmit {
            focus.wrappedValue = .workflows
          }
        if !searchTerm.isEmpty {
          Button(action: { searchTerm = "" },
                 label: { Text("Clear") })
          .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGray)))
          .font(.caption2)
        }
      }
      .padding(8)
    }

    ScrollViewReader { proxy in
      ScrollView {
        if groupsPublisher.data.isEmpty || publisher.data.isEmpty {
          ContentListEmptyView(namespace, onAction: onAction)
        } else {
          LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach($publisher.data.filter(search)) { element in
              ContentItemView(element, focusPublisher: focusPublisher, publisher: publisher,
                              contentSelectionManager: contentSelectionManager, onAction: onAction)
              .grayscale(element.wrappedValue.isEnabled ? 0 : 0.5)
              .opacity(element.wrappedValue.isEnabled ? 1 : 0.5)
              .onTapGesture {
                contentSelectionManager.handleOnTap(publisher.data, element: element.wrappedValue)
                focusPublisher.publish(element.id)
              }
              .contextMenu(menuItems: {
                contextualMenu()
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
                $publisher.data.filter(search).map(\.wrappedValue),
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
              if let firstSelection = $publisher.data.filter(search).first {
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
            }
          }
        }
      }
    }
    .id(groupSelectionManager.selections)
    .debugEdit()
  }

  @ViewBuilder
  private func contextualMenu() -> some View {
    Button("Duplicate", action: {
      onAction(.duplicate(workflowIds: contentSelectionManager.selections))
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
