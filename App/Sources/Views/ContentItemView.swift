import SwiftUI

struct ContentItemView: View {
  @ObserveInjection var inject
  let workflow: ContentViewModel

  init(_ workflow: ContentViewModel) {
    self.workflow = workflow
  }

  var body: some View {
    HStack {
      ContentImagesView(images: workflow.images)
        .frame(minWidth: 32, minHeight: 32)
        .background(Color.black.opacity(0.2).cornerRadius(8, antialiased: false))
        .overlay(alignment: .topTrailing, content: {
          Text("\(workflow.badge)")
            .aspectRatio(1, contentMode: .fill)
            .padding(1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .allowsTightening(true)
            .bold()
            .font(.caption2)
            .background(
              Color.accentColor
                .cornerRadius(32)
            )
            .frame(maxWidth: 12)
            .offset(x: 4, y: 0)
            .padding(2)
            .compositingGroup()
            .shadow(color: .black.opacity(0.75), radius: 2)
            .opacity(workflow.badgeOpacity)
        })
        .frame(width: 32, height: 32)

      Text(workflow.name)
        .lineLimit(1)
        .allowsTightening(true)

      if let binding = workflow.binding {
        Spacer()
        KeyboardShortcutView(shortcut: .init(key: binding, lhs: true, modifiers: []))
          .font(.caption)
          .allowsTightening(true)
          .frame(minWidth: 32)
          .layoutPriority(-1)
      }
    }
    .debugEdit()
  }
}
