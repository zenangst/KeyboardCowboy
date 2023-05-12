import SwiftUI

struct ContentItemView: View {
  @State var isHovered: Bool = false
  @ObserveInjection var inject
  let workflow: ContentViewModel

  init(_ workflow: ContentViewModel) {
    self.workflow = workflow
  }

  var body: some View {
    HStack {
      ContentImagesView(images: workflow.images, size: 32)
        .background(Color.black.opacity(0.2).cornerRadius(8, antialiased: false))
        .overlay(alignment: .bottomTrailing, content: {
          ContentImagesView(images: workflow.overlayImages, size: 16)
            .opacity(workflow.overlayImages.isEmpty ? 0 : 1)
        })
        .overlay(alignment: .topTrailing, content: {
          Text("\(workflow.badge)")
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
            .opacity(isHovered ? 0 : workflow.badgeOpacity)
            .animation(.default, value: isHovered)
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
    .debugEdit()
  }
}
