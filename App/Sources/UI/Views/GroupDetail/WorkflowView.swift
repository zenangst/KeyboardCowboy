import Bonzai
import SwiftUI

struct WorkflowView: View {
  private let contentSelectionManager: SelectionManager<GroupDetailViewModel>
  private let publisher: GroupDetailPublisher
  private let workflow: GroupDetailViewModel
  private let onAction: (GroupDetailView.Action) -> Void

  init(workflow: GroupDetailViewModel,
       publisher: GroupDetailPublisher,
       contentSelectionManager: SelectionManager<GroupDetailViewModel>,
       onAction: @escaping (GroupDetailView.Action) -> Void) {
    self.contentSelectionManager = contentSelectionManager
    self.workflow = workflow
    self.publisher = publisher
    self.onAction = onAction
  }

  var body: some View {
    ContentItemInternalView(
      workflow: workflow,
      publisher: publisher,
      contentSelectionManager: contentSelectionManager,
      onAction: onAction
    )
  }
}

private struct ContentItemInternalView: View {
  @State private var isHovered: Bool = false
  @State private var isSelected: Bool = false

  private let contentSelectionManager: SelectionManager<GroupDetailViewModel>
  private let publisher: GroupDetailPublisher
  private let workflow: GroupDetailViewModel
  private let onAction: (GroupDetailView.Action) -> Void

  init(workflow: GroupDetailViewModel,
       publisher: GroupDetailPublisher,
       contentSelectionManager: SelectionManager<GroupDetailViewModel>,
       onAction: @escaping (GroupDetailView.Action) -> Void) {
    self.contentSelectionManager = contentSelectionManager
    self.workflow = workflow
    self.publisher = publisher
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      WorkflowImages(images: workflow.images, size: 32)
        .background(
          Color.black.opacity(0.3).cornerRadius(8, antialiased: false)
        )
        .overlay(alignment: .bottomTrailing, content: {
          WorkflowDisabledOverlay(isEnabled: workflow.isEnabled)
        })
        .overlay(alignment: .topTrailing,
                 content: {
          WorkflowBadge(isHovered: $isHovered,
                                      text: "\(workflow.badge)",
                                      badgeOpacity: workflow.badgeOpacity)
          .offset(x: 4, y: 0)
        })
        .overlay(alignment: .topLeading) {
          ContentExecutionView(execution: workflow.execution)
        }
        .fixedSize()
        .frame(width: 32, height: 32)
        .onHover { newValue in
          isHovered <- newValue
        }
        .compositingGroup()
        .zIndex(2)

      Text(workflow.name)
        .lineLimit(1)
        .allowsTightening(true)
        .frame(maxWidth: .infinity, alignment: .leading)

      ContentItemAccessoryView(workflow: workflow)
    }
    .padding(4)
    .background(ItemBackgroundView(workflow.id, selectionManager: contentSelectionManager))
    .draggable(workflow)
  }
}

private struct ContentExecutionView: View {
  let execution: GroupDetailViewModel.Execution
  var body: some View {
    Group {
      switch execution {
      case .concurrent:
        EmptyView()
      case .serial:
        Image(systemName: "square.3.layers.3d.top.filled")
          .resizable()
          .background(
            Circle()
              .fill(Color.accentColor)
          )
          .compositingGroup()
          .shadow(color: .black.opacity(0.75), radius: 2)
      }
    }
    .aspectRatio(contentMode: .fit)
    .frame(width: 12, height: 12)
  }
}

struct ItemBackgroundView<T: Hashable & Identifiable>: View where T.ID == String {
  private let id: T.ID
  @ObservedObject private var selectionManager: SelectionManager<T>

  init(_ id: T.ID, selectionManager: SelectionManager<T>) {
    self.id = id
    self.selectionManager = selectionManager
  }

  var body: some View {
    FillBackgroundView(
      isSelected: Binding<Bool>.readonly(selectionManager.selections.contains(id))
    )
  }
}

private struct ContentItemAccessoryView: View {
  let workflow: GroupDetailViewModel

  @ViewBuilder
  var body: some View {
    switch workflow.trigger {
    case .application:
      GenericAppIconView(size: 16)
    case .keyboard(let binding):
      KeyboardShortcutView(shortcut: .init(key: binding, modifiers: []))
        .fixedSize()
        .font(.footnote)
        .lineLimit(1)
        .allowsTightening(true)
        .frame(minWidth: 32, alignment: .trailing)
    case .snippet(let snippet):
      HStack(spacing: 1) {
        Text(snippet)
          .font(.footnote)
        SnippetIconView(size: 12)
      }
      .lineLimit(1)
      .allowsTightening(true)
      .truncationMode(.tail)
      .padding(1)
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.separatorColor), lineWidth: 1)
      )
    case .none:
      EmptyView()
    }
  }
}

#Preview {
  ForEach(DesignTime.contentPublisher.data) { workflow in
    WorkflowView(
      workflow: workflow,
      publisher: DesignTime.contentPublisher,
      contentSelectionManager: SelectionManager<GroupDetailViewModel>()
    ) { _ in }
  }

  .designTime()
}
