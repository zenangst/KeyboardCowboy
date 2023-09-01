import SwiftUI

struct ContentItemView: View {
  private var focusPublisher: FocusPublisher<ContentViewModel>
  @ObservedObject private var contentSelectionManager: SelectionManager<ContentViewModel>
  @State var isHovered: Bool = false
  @State var isTargeted: Bool = false
  @ObserveInjection var inject
  private let publisher: ContentPublisher
  private let workflow: Binding<ContentViewModel>
  private let onAction: (ContentListView.Action) -> Void

  init(_ workflow: Binding<ContentViewModel>,
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
      ContentImagesView(images: workflow.wrappedValue.images, size: 32)
        .background(
          Color.black.opacity(0.3).cornerRadius(8, antialiased: false)
            .frame(maxWidth: 32)
        )
        .overlay(alignment: .bottomTrailing, content: {
          ZStack {
            Circle()
              .fill(Color.white)
              .frame(width: 14, height: 14)
            Image(systemName: "pause.circle.fill")
              .resizable()
              .foregroundStyle(Color.accentColor)
              .frame(width: 12, height: 12)
          }
          .opacity(!workflow.wrappedValue.isEnabled ? 1 : 0)
        })
        .overlay(alignment: .topTrailing, content: {
          Text("\(workflow.wrappedValue.badge)")
            .aspectRatio(1, contentMode: .fill)
            .padding(1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .allowsTightening(true)
            .bold()
            .font(.caption2)
            .padding(2)
            .background(
              Circle()
                .fill(Color.accentColor)
            )
            .frame(maxWidth: 12)
            .offset(x: 4, y: 0)
            .compositingGroup()
            .shadow(color: .black.opacity(0.75), radius: 2)
            .opacity(isHovered ? 0 : workflow.wrappedValue.badgeOpacity)
            .animation(.default, value: isHovered)
        })
        .fixedSize()
        .frame(width: 32, height: 32)
        .onHover { newValue in
          isHovered <- newValue
        }
        .compositingGroup()
        .zIndex(2)

      Text(workflow.wrappedValue.name)
        .lineLimit(1)
        .allowsTightening(true)

      Spacer()
      if let binding = workflow.wrappedValue.binding {
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
      FocusView(focusPublisher, element: workflow,
                isTargeted: $isTargeted,
                selectionManager: contentSelectionManager,
                cornerRadius: 4, style: .list)
    )
    .draggable(getDraggable())
    .dropDestination(for: String.self) { items, location in
      guard let payload = items.draggablePayload(prefix: "W|"),
            let (from, destination) = publisher.data.moveOffsets(for: workflow.wrappedValue, with: payload) else {
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
