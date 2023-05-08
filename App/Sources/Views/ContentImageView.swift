import SwiftUI

struct ContentImageView: View {
  let image: ContentViewModel.ImageModel
  let size: CGFloat

  var body: some View {
    switch image.kind {
    case .icon(let icon):
      Group {
        IconView(icon: icon, size: .init(width: size, height: size))
          .id(icon)
      }
    case .command(let kind):
      switch kind {
      case .keyboard(let keys):
        ZStack {
          ForEach(keys) { key in
            RegularKeyIcon(letter: key.key)
              .scaleEffect(0.8)

            ForEach(key.modifiers) { modifier in
              HStack {
                ModifierKeyIcon(key: modifier)
                  .scaleEffect(0.4, anchor: .bottomLeading)
                  .opacity(0.8)
              }
              .padding(4)
            }
          }
        }
        .rotationEffect(.degrees(-(3.75 * image.offset)))
        .offset(.init(width: -(image.offset * 1.25),
                      height: image.offset * 1.25))
      case .application:
       EmptyView()
      case .open:
        EmptyView()
      case .script(let scriptKind):
        switch scriptKind {
        case .inline:
          ZStack {
            Rectangle()
              .fill(LinearGradient(stops: [
                .init(color: Color.accentColor.opacity(0.2), location: 0.0),
                .init(color: .black, location: 0.2),
                .init(color: .black, location: 1.0),
              ], startPoint: .top, endPoint: .bottom))
              .cornerRadius(8)
              .scaleEffect(0.9)
            RoundedRectangle(cornerRadius: 8)
              .stroke(.black)
              .scaleEffect(0.9)

            Text(">_")
              .font(Font.system(.caption, design: .monospaced))
          }
        case .path:
          Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Script Editor.app"))
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 32)
        }
      case .shortcut:
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Shortcuts.app"))
          .resizable()
          .aspectRatio(1, contentMode: .fill)
          .frame(width: 32)
      case .type:
        RegularKeyIcon(letter: "(...)", width: 25, height: 25)
          .frame(width: 24, height: 24)
      case .plain, .systemCommand:
        EmptyView()
      }
    }
  }
}
