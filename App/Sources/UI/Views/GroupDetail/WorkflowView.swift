import Bonzai
import Inject
import SwiftUI

struct WorkflowView: View {
  @ObserveInjection var inject
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
    WorkflowViewItemInternalView(
      workflow: workflow,
      publisher: publisher,
      contentSelectionManager: contentSelectionManager,
      onAction: onAction
    )
    .enableInjection()
  }
}

private struct WorkflowViewItemInternalView: View {
  @ObserveInjection var inject
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
    HStack(spacing: 4) {
      WorkflowImages(images: workflow.images, size: 32)
        .opacity(workflow.isEnabled ? 1.0 : 0.5)
        .grayscale(workflow.isEnabled ? 0.0 : 1.0)
        .background(
          Color.black.opacity(0.3).cornerRadius(8, antialiased: false)
        )
        .overlay(alignment: .topTrailing) {
          WorkflowBadge(isHovered: $isHovered,
                        text: "\(workflow.badge)",
                        badgeOpacity: workflow.badgeOpacity)
          .offset(x: 4, y: 0)
        }
        .fixedSize()
        .frame(width: 32, height: 32)
        .onHover { newValue in
          isHovered <- newValue
        }
        .compositingGroup()
        .zIndex(2)

      VStack(alignment: .leading, spacing: 0) {
        Text(workflow.name)
          .lineLimit(1)
          .allowsTightening(true)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text("Disabled")
          .opacity(workflow.isEnabled ? 0 : 1)
          .frame(maxHeight: workflow.isEnabled ? 0 : nil)
          .font(.caption)
      }

      HStack(spacing: 2) {
        ContentItemAccessoryView(workflow: workflow)
        ExecutionView(execution: workflow.execution)
      }
    }
    .padding(4)
    .background(ItemBackgroundView(workflow.id, selectionManager: contentSelectionManager))
    .draggable(workflow)
    .enableInjection()
  }
}

private struct ExecutionView: View {
  @ObserveInjection var inject
  let execution: GroupDetailViewModel.Execution
  var body: some View {
    Image(systemName: execution == .concurrent ? "arrow.branch" : "list.bullet")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .compositingGroup()
      .shadow(color: .black.opacity(0.75), radius: 2)
      .frame(width: 10, height: 10)
      .padding(3)
      .background()
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.separatorColor), lineWidth: 1)
      )
      .help(execution == .concurrent ? "Concurrent" : "Serial")
      .enableInjection()
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
      isSelected: Binding<Bool>.readonly { selectionManager.selections.contains(id) }
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
