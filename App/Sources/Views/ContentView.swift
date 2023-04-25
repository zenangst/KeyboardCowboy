import Foundation
import SwiftUI
import Inject
import UniformTypeIdentifiers

struct ContentView: View {
  @ObserveInjection var inject

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

  @Environment(\.controlActiveState) var controlActiveState
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

  private func getColor() -> NSColor {
    let color: NSColor
    if let groupId = groupIds.data.ids.first,
       let group = groupsPublisher.data.first(where: { $0.id == groupId }) {
      color = .init(hex: group.color).blended(withFraction: 0.4, of: .black)!
    } else {
      color = .controlAccentColor.blended(withFraction: 1.0, of: .white)!
    }
    return color
  }

  @ViewBuilder
  func selectedBackground(_ workflow: ContentViewModel) -> some View {
    Group {
      if publisher.selections.contains(workflow.id) {
        Color(nsColor: getColor())
      }
    }
    .cornerRadius(4, antialiased: true)
    .padding(.horizontal, 10)
    .grayscale(controlActiveState == .active ? 0.0 : 0.5)
    .opacity(focus ? 1 : 0.1)
  }

  var body: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        headerView()

        if groupsPublisher.data.isEmpty || publisher.data.isEmpty {
          emptyView()
        }

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
              .listRowBackground(selectedBackground(workflow))
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
      .scrollContentBackground(.hidden)
      .background(
        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.5),
          .init(color: Color(nsColor: .gridColor), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .debugEdit()
    }
    .enableInjection()
  }

  private func headerView() -> some View {
    VStack(alignment: .leading) {
      if let groupId = groupIds.data.ids.first,
         let group = groupsPublisher.data.first(where: { $0.id == groupId }) {
        Label("Group", image: "")
          .labelStyle(SidebarLabelStyle())
          .padding(.leading, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 6)
        HStack(spacing: 12) {
          GroupIconView(color: group.color, icon: group.icon, symbol: group.symbol)
            .frame(width: 24, height: 24)
          Text(group.name)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 14)
        .font(.headline)
      }
      Label("Workflows", image: "")
        .labelStyle(SidebarLabelStyle())
        .padding(.leading, 8)
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
        .padding(.top, 16)
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
