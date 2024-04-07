import Bonzai
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
    .background(ItemBackgroundView(workflow.id, selectionManager: contentSelectionManager))
    .draggable(workflow)
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
  let workflow: ContentViewModel

  @ViewBuilder
  var body: some View {
    switch workflow.trigger {
    case .application:
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
