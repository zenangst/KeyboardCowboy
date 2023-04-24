import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  enum Action: Hashable {
    case rerender
    case moveWorkflowsToGroup(_ groupId: WorkflowGroup.ID, workflows: [ContentViewModel.ID])
    case selectWorkflow(models: [ContentViewModel.ID], inGroups: [WorkflowGroup.ID])
    case removeWorflows([ContentViewModel.ID])
    case moveWorkflows(source: IndexSet, destination: Int)
    case addWorkflow(workflowId: Workflow.ID)
    case addCommands(workflowId: Workflow.ID, commandIds: [DetailViewModel.CommandViewModel.ID])
  }

  static var appStorage: AppStorageStore = .init()

  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher
  @EnvironmentObject private var groupIds: GroupIdsPublisher

  @FocusState var focus: Bool
  @Environment(\.resetFocus) var resetFocus
  @Namespace var namespace

  @State var overlayOpacity: CGFloat = 1

  private let moveManager: MoveManager<ContentViewModel> = .init()
  private let selectionManager: SelectionManager<ContentViewModel> = .init(Array(Self.appStorage.workflowIds).last)

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    if groupsPublisher.data.isEmpty {
      emptyView()
    } else {
      content()
    }
  }

  private func emptyView() -> some View {
    Text("Add a group before adding a workflow.")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
      .multilineTextAlignment(.center)
      .foregroundColor(Color(.systemGray))
  }

  @ViewBuilder
  private func content() -> some View {
    ScrollViewReader { proxy in
      List(selection: $publisher.selections) {
        ForEach(publisher.data) { workflow in
          ContentItemView(workflow)
            .contentShape(Rectangle())
            .onTapGesture {
              selectionManager.handleOnTap(
                publisher.data,
                element: workflow,
                selections: &publisher.selections)
              focus = true
              resetFocus.callAsFunction(in: namespace)
            }
            .draggable(workflow)
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
        }
        .onMove { source, destination in
          onAction(.moveWorkflows(source: source, destination: destination))
        }
        .dropDestination(for: ContentViewModel.self) { items, index in
          let source = moveManager.onDropDestination(
            items, index: index,
            data: publisher.data,
            selections: publisher.selections)
          onAction(.moveWorkflows(source: source, destination: index))
        }
        .focused($focus)
        .onDeleteCommand(perform: {
          guard !publisher.selections.isEmpty else { return }
          onAction(.removeWorflows(Array(publisher.selections)))
        })
        .onChange(of: publisher.selections, perform: { newValue in
          onAction(.selectWorkflow(models: Array(newValue), inGroups: groupIds.data.ids))
          if let first = newValue.first {
            proxy.scrollTo(first)
          }
        })
        .overlay(alignment: .top, content: { overlayView() })
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

  private func overlayView() -> some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color(.gridColor))
        .frame(height: 36)
      Rectangle()
        .fill(Color.gray)
        .frame(height: 1)
        .opacity(0.25)
      Rectangle()
        .fill(Color.black)
        .frame(height: 1)
        .opacity(0.5)
    }
    .opacity(overlayOpacity)
    .allowsHitTesting(false)
    .shadow(color: Color(.gridColor), radius: 8, x: 0, y: 2)
    .edgesIgnoringSafeArea(.top)
  }

  @ViewBuilder
  private func contextualMenu() -> some View {
    Menu("Move to") {
      // Show only other groups than the current one.
      ForEach(groupsPublisher.data.filter({ !groupIds.data.ids.contains($0.id) })) { group in
        Button(group.name) {
          onAction(.moveWorkflowsToGroup(group.id, workflows: Array(publisher.selections)))
        }
      }
    }
    Button("Delete", action: {
      onAction(.removeWorflows(publisher.selections.map { $0 }))
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView { _ in }
      .designTime()
      .frame(height: 900)
  }
}
