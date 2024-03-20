import Bonzai
import Inject
import SwiftUI

struct ContentItemView: View {
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let publisher: ContentPublisher
  private let workflow: ContentViewModel
  private let onAction: (ContentListView.Action) -> Void

  init(workflow: ContentViewModel,
       publisher: ContentPublisher,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (ContentListView.Action) -> Void) {
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

  private let contentSelectionManager: SelectionManager<ContentViewModel>
  private let publisher: ContentPublisher
  private let workflow: ContentViewModel
  private let onAction: (ContentListView.Action) -> Void

  init(workflow: ContentViewModel,
       publisher: ContentPublisher,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (ContentListView.Action) -> Void) {
    self.contentSelectionManager = contentSelectionManager
    self.workflow = workflow
    self.publisher = publisher
    self.onAction = onAction
  }

  var body: some View {
    HStack {
      ContentImagesView(images: workflow.images, size: 32)
        .background(
          Color.black.opacity(0.3).cornerRadius(8, antialiased: false)
        )
        .overlay(alignment: .bottomTrailing, content: {
          ContentItemIsDisabledOverlayView(isEnabled: workflow.isEnabled)
        })
        .overlay(alignment: .topTrailing,
                 content: {
          ContentItemBadgeOverlayView(isHovered: $isHovered,
                                      text: "\(workflow.badge)",
                                      badgeOpacity: workflow.badgeOpacity)
          .offset(x: 4, y: 0)
        })
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
    .background(ContentItemBackgroundView(workflow.id, contentSelectionManager: contentSelectionManager))
    .draggable(workflow)
  }
}

private struct ContentItemBackgroundView: View {
  private let workflowId: ContentViewModel.ID
  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @State private var isSelected: Bool

  init(_ workflowId: ContentViewModel.ID, contentSelectionManager: SelectionManager<ContentViewModel>) {
    self.workflowId = workflowId
    self.contentSelectionManager = contentSelectionManager
    self.isSelected = contentSelectionManager.selections.contains(workflowId)
  }

  var body: some View {
    FillBackgroundView(isSelected: $isSelected)
    .onChange(of: contentSelectionManager.selections, perform: { _ in
      isSelected = contentSelectionManager.selections.contains(workflowId)
    })
  }
}

private struct ContentItemAccessoryView: View {
  let workflow: ContentViewModel

  @ViewBuilder
  var body: some View {
    switch workflow.trigger {
    case .application(let application):
      GenericAppIconView(size: 16)
    case .keyboard(let binding):
      KeyboardShortcutView(shortcut: .init(key: binding, lhs: true, modifiers: []))
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
