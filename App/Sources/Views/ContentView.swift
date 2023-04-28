import Foundation
import SwiftUI
import UniformTypeIdentifiers

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

  @FocusState var focus: AppFocus?
  @Environment(\.resetFocus) var resetFocus

  @State var overlayOpacity: CGFloat = 1

  private let debounceSelectionManager: DebounceManager<Set<String>>
  private let moveManager: MoveManager<ContentViewModel> = .init()
  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @ObservedObject private var groupSelectionManager: SelectionManager<GroupViewModel>

  private let onAction: (Action) -> Void

  init(contentSelectionManager: SelectionManager<ContentViewModel>,
       groupSelectionManager: SelectionManager<GroupViewModel>,
       onAction: @escaping (Action) -> Void) {
    _contentSelectionManager = .init(initialValue: contentSelectionManager)
    _groupSelectionManager = .init(initialValue: groupSelectionManager)
    self.onAction = onAction
    self.debounceSelectionManager = .init(contentSelectionManager.selections, milliseconds: 150, onUpdate: {
      onAction(.selectWorkflow(workflowIds: $0, groupIds: groupSelectionManager.selections))
    })
  }

  var body: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        headerView()
        if groupsPublisher.data.isEmpty || publisher.data.isEmpty {
          emptyView()
        } else {
          list(proxy)
        }
      }
      .scrollContentBackground(.hidden)
      .background(
        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.5),
          .init(color: Color(nsColor: .gridColor), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .debugEdit()
    }
  }

  private func list(_ proxy: ScrollViewProxy) -> some View {
    List(selection: $contentSelectionManager.selections) {
      ForEach(publisher.data) { workflow in
        ContentItemView(workflow)
          .contentShape(Rectangle())
          .onTapGesture {
            contentSelectionManager.handleOnTap(publisher.data, element: workflow)
            focus = .workflows
          }
          .draggable(DraggableView.workflow([workflow]))
          .onFrameChange(perform: { rect in
            // TODO: (Quickfix) Find a better solution for contentOffset observation.
            if workflow == publisher.data.first && rect.origin.y != 52 {
              let value = min(max(1.0 - rect.origin.y / 52.0, 0.0), 0.9)
              overlayOpacity <- value
            }
          })
          .grayscale(workflow.isEnabled ? 0 : 0.5)
          .opacity(workflow.isEnabled ? 1 : 0.5)
          .contextMenu(menuItems: {
            contextualMenu()
          })
          .tag(workflow.id)
          .id(workflow.id)
          .listRowBackground(
            ContentBackgroundView(
              focus: $focus,
              data: groupsPublisher.data,
              groupSelectionManager: groupSelectionManager,
              contentSelectionManager: contentSelectionManager,
              workflow: workflow)
          )
      }
      .onMove { source, destination in
        onAction(.moveWorkflows(source: source, destination: destination))
      }
      .dropDestination(for: DraggableView.self) { items, index in
        for item in items {
          switch item {
          case .workflow(let workflows):
            let source = moveManager.onDropDestination(
              workflows, index: index,
              data: publisher.data,
              selections: contentSelectionManager.selections)
            onAction(.moveWorkflows(source: source, destination: index))
          default:
            break
          }
        }
      }
    }
    .focused($focus, equals: .workflows)
    .onDeleteCommand(perform: {
      guard !contentSelectionManager.selections.isEmpty else { return }
      onAction(.removeWorflows(contentSelectionManager.selections))
    })
    .onChange(of: contentSelectionManager.selections, perform: { newValue in
      debounceSelectionManager.process(newValue)
      if let first = newValue.first { proxy.scrollTo(first) }
    })
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
                .frame(width: 16, height: 16)
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
      ForEach(groupsPublisher.data.filter({ !groupSelectionManager.selections.contains($0.id) })) { group in
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
  static var previews: some View {
    ContentView(contentSelectionManager: .init(), groupSelectionManager: .init()) { _ in }
      .designTime()
      .frame(height: 900)
  }
}
