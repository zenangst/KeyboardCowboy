import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ContentDebounce: DebounceSnapshot {
  let workflows: Set<ContentViewModel.ID>
  let groups: Set<GroupViewModel.ID>
}

struct ContentView: View {
  @ObserveInjection var inject

  enum Action: Hashable {
    case rerender(_ groupIds: Set<WorkflowGroup.ID>)
    case moveWorkflowsToGroup(_ groupId: WorkflowGroup.ID, workflows: Set<ContentViewModel.ID>)
    case selectWorkflow(workflowIds: Set<ContentViewModel.ID>, groupIds: Set<WorkflowGroup.ID>)
    case removeWorflows(Set<ContentViewModel.ID>)
    case moveWorkflows(source: IndexSet, destination: Int)
    case addWorkflow(workflowId: Workflow.ID)
    case addCommands(workflowId: Workflow.ID, commandIds: [DetailViewModel.CommandViewModel.ID])
  }

  static var appStorage: AppStorageStore = .init()

  @Environment(\.controlActiveState) var controlActiveState
  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher

  @Environment(\.resetFocus) var resetFocus

  @State var overlayOpacity: CGFloat = 1

  private var focus: FocusState<AppFocus?>.Binding
  private let debounceSelectionManager: DebounceManager<ContentDebounce>
  private var focusPublisher = FocusPublisher<ContentViewModel>()

  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @ObservedObject private var groupSelectionManager: SelectionManager<GroupViewModel>

  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    _contentSelectionManager = .init(initialValue: contentSelectionManager)
    _groupSelectionManager = .init(initialValue: groupSelectionManager)
    self.focus = focus
    self.onAction = onAction
    self.debounceSelectionManager = .init(
      ContentDebounce(workflows: contentSelectionManager.selections,
                      groups: groupSelectionManager.selections), milliseconds: 100, onUpdate: { snapshot in
      onAction(.selectWorkflow(workflowIds: snapshot.workflows, groupIds: snapshot.groups))
    })
  }

  var body: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        GroupHeaderView(groupSelectionManager: groupSelectionManager)
        if groupsPublisher.data.isEmpty || publisher.data.isEmpty {
          emptyView()
        } else {
          list(proxy)
        }
      }
      .background(
        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.5),
          .init(color: Color(nsColor: .gridColor), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .debugEdit()
    }
  }

  private func getDraggedWorkflows(_ workflow: ContentViewModel) -> [ContentViewModel] {
    let workflows: [ContentViewModel]
    if contentSelectionManager.selections.contains(workflow.id) {
      workflows = publisher.data
        .filter { contentSelectionManager.selections.contains($0.id) }
    } else {
      workflows = [workflow]
    }
    return workflows
  }

  private func list(_ proxy: ScrollViewProxy) -> some View {
    ScrollView {
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
      .focused(focus, equals: .workflows)
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
  private func headerView() -> some View {
    VStack(alignment: .leading) {
      if let groupId = groupSelectionManager.selections.first,
         let group = groupsPublisher.data.first(where: { $0.id == groupId }) {
        Label("Group", image: "")
          .labelStyle(SidebarLabelStyle())
          .padding(.leading, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 6)
        HStack(spacing: 8) {
          GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
            .fixedSize()
            .frame(width: 24, height: 24)
            .padding(4)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .init(hex: group.color)).opacity(0.4))
            )
          VStack(alignment: .leading) {
            Text(group.name)
              .font(.headline)
            Text("Workflows: \(group.count)")
              .font(.caption)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 4)
        .padding(.leading, 14)
        .id(group)
      }

        Label("Workflows", image: "")
          .labelStyle(SidebarLabelStyle())
          .padding(.leading, 8)
          .padding(.bottom, 4)
          .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func emptyView() -> some View {
    ScrollView {
      if groupsPublisher.data.isEmpty {
        Text("Add a group before adding a workflow.")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.systemGray))
      } else if publisher.data.isEmpty {
        VStack(spacing: 8) {
          Button(action: {
            withAnimation {
              onAction(.addWorkflow(workflowId: UUID().uuidString))
            }
          }, label: {
            HStack(spacing: 8) {
              Image(systemName: "plus.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fixedSize()
                .frame(width: 16, height: 16)
              Divider()
                .opacity(0.5)
              Text("Add Workflow")
            }
            .padding(4)
          })
          .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen, hoverEffect: false)))

          Text("No workflows yet,\nadd a workflow to get started.")
            .multilineTextAlignment(.center)
            .font(.footnote)
            .padding(.top, 8)
        }
        .padding(.top, 128)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }

  private func divider() -> some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color(nsColor: .textBackgroundColor))
      Rectangle()
        .fill(Color.gray)
        .frame(height: 1)
        .opacity(0.15)
      Rectangle()
        .fill(Color.black)
        .frame(height: 1)
        .opacity(0.5)
    }
    .allowsHitTesting(false)
    .shadow(color: Color(.gridColor), radius: 8, x: 0, y: 2)
    .edgesIgnoringSafeArea(.top)
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

struct ContentView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    ContentView($focus, contentSelectionManager: .init(), groupSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 900)
  }
}

final class ContentViewItemProvider: NSObject, NSSecureCoding, NSItemProviderWriting, NSItemProviderReading {
  static var supportsSecureCoding: Bool = true
  static var writableTypeIdentifiersForItemProvider = [UTType.workflow.identifier]
  static var readableTypeIdentifiersForItemProvider = [UTType.workflow.identifier]

  let items: [ContentViewModel]

  init(items: [ContentViewModel]) {
    self.items = items
    super.init()
  }

  init?(coder: NSCoder) {
    guard let items = coder.decodeObject(forKey: "items") as? [ContentViewModel] else {
      return nil
    }
    self.items = items
  }

  static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
    do {
      let decoder = JSONDecoder()
      let items = try decoder.decode([ContentViewModel].self, from: data)
      return ContentViewItemProvider(items: items) as! Self
    }
  }

  func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
    do {
      let encoder = JSONEncoder()
      let data = try encoder.encode(items)
      completionHandler(data, nil)
    } catch {
      completionHandler(nil, error)
    }
    return nil
  }

  // MARK: - NSSecureCoding

    func encode(with coder: NSCoder) {
      coder.encode(items, forKey: "items")
    }

}

final class ContentViewDropDelegate: DropDelegate {
  func performDrop(info: DropInfo) -> Bool {
    Swift.print("🐾 \(#file) - \(#function):\(#line)")
    return true
  }

  func dropEntered(info: DropInfo) {
    Swift.print("🐾 \(#file) - \(#function):\(#line)")
  }

  func dropExited(info: DropInfo) {
    Swift.print("🐾 \(#file) - \(#function):\(#line)")
  }

  func validateDrop(info: DropInfo) -> Bool {
    Swift.print("🐾 \(#file) - \(#function):\(#line)")
    return true
  }
}
