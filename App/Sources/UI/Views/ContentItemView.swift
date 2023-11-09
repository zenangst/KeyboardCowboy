import SwiftUI

@MainActor
struct ContentItemView: View {
  @Environment(\.isFocused) private var isFocused
  private let contentSelectionManager: SelectionManager<ContentViewModel>
  @State var isHovered: Bool = false
  @State var isTargeted: Bool = false
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
            .frame(maxWidth: 32)
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

      if let binding = workflow.binding {
        KeyboardShortcutView(shortcut: .init(key: binding, lhs: true, modifiers: []))
          .fixedSize()
          .font(.caption)
          .lineLimit(1)
          .allowsTightening(true)
          .frame(minWidth: 32, alignment: .trailing)
      }
    }
    .padding(4)
    .background(FillBackgroundView(selectionManager: contentSelectionManager, id: workflow.id))
    .draggable(getDraggable())
    .dropDestination(for: String.self) { items, location in
      guard let payload = items.draggablePayload(prefix: "W|"),
            let (from, destination) = publisher.data.moveOffsets(for: workflow, with: payload) else {
        return false
      }
      withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
        publisher.data.move(fromOffsets: IndexSet(from), toOffset: destination)
      }
      onAction(.reorderWorkflows(source: from, destination: destination))
      return true
    } isTargeted: { newValue in
      isTargeted = newValue
    }
  }

  func getDraggable() -> String {
    return workflow.draggablePayload(prefix: "W|", selections: contentSelectionManager.selections)
  }
}
