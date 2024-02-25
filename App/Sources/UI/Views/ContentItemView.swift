import Bonzai
import Inject
import SwiftUI

@MainActor
struct ContentItemView: View {
  @ObserveInjection var inject
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
          .font(.footnote)
          .lineLimit(1)
          .allowsTightening(true)
          .frame(minWidth: 32, alignment: .trailing)
      } else if let snippet = workflow.snippet {
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
      }
    }
    .padding(4)
    .background(FillBackgroundView(isSelected: .readonly(contentSelectionManager.selections.contains(workflow.id))))
    .draggable(workflow)
  }
}
