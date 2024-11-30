import SwiftUI

struct DockIconView: View {
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(Color(.controlAccentColor))
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay(alignment: .top) {
        Rectangle()
          .opacity(0.6)
          .frame(height: size * 0.15)
      }
      .overlay(alignment: .bottom) {
        RoundedRectangle(cornerRadius: size * 0.0425)
          .frame(width: size * 0.75, height: size * 0.15)
          .overlay(alignment: .top) {
          }
          .offset(y: -size * 0.075)
          .rotation3DEffect(.degrees(15), axis: (x: 1.0, y: 0.0, z: 0.0))
      }
      .overlay(alignment: .bottom, content: {
        HStack(spacing: size * 0.0_340) {
          let iconSize = size * 0.125
          Rectangle()
            .iconShape(size * 0.1)
            .overlay { iconOverlay().opacity(0.5) }
            .overlay { iconBorder(size * 0.1) }
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)

          Rectangle()
            .iconShape(size * 0.1)
            .overlay { iconOverlay().opacity(0.5) }
            .overlay { iconBorder(size * 0.1) }
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)

          Rectangle()
            .iconShape(size * 0.1)
            .overlay { iconOverlay().opacity(0.5) }
            .overlay { iconBorder(size * 0.1) }
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)

          Rectangle()
            .iconShape(size * 0.1)
            .overlay { iconOverlay().opacity(0.5) }
            .overlay { iconBorder(size * 0.1) }
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)
        }
        .offset(y: -size * 0.075)
      })
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
  }
}

#Preview {
  IconPreview { DockIconView(size: $0) }
}
