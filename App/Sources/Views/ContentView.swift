import Foundation
import SwiftUI

struct ContentView: View {
  enum Action: Hashable {
    case rerender
    case selectWorkflow(models: [ContentViewModel.ID], inGroups: [WorkflowGroup.ID])
    case removeWorflows([ContentViewModel.ID])
    case moveWorkflows(source: IndexSet, destination: Int)
    case addWorkflow(workflowId: Workflow.ID)
    case addCommands(workflowId: Workflow.ID, commandIds: [DetailViewModel.CommandViewModel.ID])
  }

  @EnvironmentObject private var groupsPublisher: GroupsPublisher
  @EnvironmentObject private var publisher: ContentPublisher
  @EnvironmentObject private var groupIds: GroupIdsPublisher

  @State private var dropOverlayIsVisible: Bool = false
  @State var selected = Set<ContentViewModel.ID>()
  @State var overlayOpacity: CGFloat = 0
  @State var dropCommands = Set<DetailViewModel.CommandViewModel>()

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
      List(selection: $publisher.selections) {
        ForEach(publisher.models) { workflow in
          ContentItemView(workflow: workflow)
            .onFrameChange(perform: { rect in
              if workflow == publisher.models.first {
                let value = min(max(1.0 - rect.origin.y / 52.0, 0.0), 0.9)
                overlayOpacity = value
              }
            })
            .grayscale(workflow.isEnabled ? 0 : 0.5)
            .opacity(workflow.isEnabled ? 1 : 0.5)
            .contextMenu(menuItems: {
              contextualMenu()
            })
            .onDrop(of: GenericDroplet<DetailViewModel.CommandViewModel>.writableTypeIdentifiersForItemProvider,
                    delegate: AppDropDelegate(isVisible: $dropOverlayIsVisible,
                                              dropElements: $dropCommands,
                                              onDrop: { models in
              onAction(.addCommands(workflowId: workflow.id, commandIds: models.map(\.id)))
            }))
            .tag(workflow.id)
            .id(workflow.id)
        }
        .onMove { source, destination in
          onAction(.moveWorkflows(source: source, destination: destination))
        }
      }
      .onDeleteCommand(perform: {
        guard !publisher.selections.isEmpty else { return }
        onAction(.removeWorflows(Array(publisher.selections)))
      })
      .onChange(of: publisher.selections, perform: { newValue in
        selected = newValue
        onAction(.selectWorkflow(models: Array(newValue), inGroups: groupIds.model.ids))
        if let first = newValue.first {
          proxy.scrollTo(first)
        }
      })
      .overlay(alignment: .top, content: { overlayView() })
      .toolbar {
        ToolbarItemGroup(placement: .navigation) {
          if !groupsPublisher.models.isEmpty {
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

  private func contextualMenu() -> some View {
    Button("Delete", action: {
      onAction(.removeWorflows(publisher.selections.map { $0 }))
    })
  }
}

struct GeometryPreferenceKeyView<Key: PreferenceKey>: ViewModifier {
    typealias Transform = (GeometryProxy) -> Key.Value
    private let space: CoordinateSpace
    private let transform: Transform

    init(space: CoordinateSpace, transform: @escaping Transform) {
        self.space = space
        self.transform = transform
    }

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { Color.clear.preference(key: Key.self, value: transform($0)) })
    }
}

struct FramePreferenceKey: PreferenceKey {
    typealias Value = CGRect
    static var defaultValue = CGRect.zero

    static func reduce(value: inout Value, nextValue: () -> Value) { }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView { _ in }
      .designTime()
      .frame(height: 900)
  }
}

extension View {
  func onFrameChange(space: CoordinateSpace = .global, perform: @escaping (CGRect) -> Void) -> some View {
      self
          .modifier(GeometryPreferenceKeyView<FramePreferenceKey>(space: space, transform: { $0.frame(in: space) }))
          .onPreferenceChange(FramePreferenceKey.self, perform: perform)
  }
}
