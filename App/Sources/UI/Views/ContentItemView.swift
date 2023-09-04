import SwiftUI

struct ContentItemView: View {
  private var focusPublisher: FocusPublisher<ContentViewModel>
  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @State var isHovered: Bool = false
  @State var isTargeted: Bool = false
  @ObserveInjection var inject
  private let publisher: ContentPublisher
  private let workflow: ContentViewModel
  private let onAction: (ContentListView.Action) -> Void

  init(_ workflow: ContentViewModel,
       focusPublisher: FocusPublisher<ContentViewModel>,
       publisher: ContentPublisher,
       contentSelectionManager: SelectionManager<ContentViewModel>,
       onAction: @escaping (ContentListView.Action) -> Void) {
    self.contentSelectionManager = contentSelectionManager
    self.workflow = workflow
    self.focusPublisher = focusPublisher
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

      Spacer()
      if let binding = workflow.binding {
        KeyboardShortcutView(shortcut: .init(key: binding, lhs: true, modifiers: []))
          .font(.caption)
          .allowsTightening(true)
          .frame(minWidth: 32, maxWidth: .infinity, alignment: .trailing)
          .layoutPriority(-1)
      }
    }
    .contentShape(Rectangle())
    .padding(4)
    .background(
      FocusView(focusPublisher, element: Binding.readonly(workflow),
                isTargeted: $isTargeted,
                selectionManager: contentSelectionManager,
                cornerRadius: 4, style: .list)
    )
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
