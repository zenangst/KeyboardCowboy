import SwiftUI

struct WindowSwitcherIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(nsColor: .systemPink))
      .overlay {
        LinearGradient(
          stops: [
            Gradient.Stop(color: Color(nsColor: .systemRed), location: 0),
            Gradient.Stop(color: .clear, location: 0.5)
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color.white, location: 0.25),
          .init(color: Color(nsColor: .systemPink), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
        .mask {
          Group {
            RoundedRectangle(cornerRadius: size / 8)
              .fill(Color.white.opacity(0.7))
              .offset(x: -size * 0.1, y: -size * 0.1)
              .frame(width: size * 0.6, height: size * 0.5)

            Image(systemName: "appwindow.swipe.rectangle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .offset(x: size * 0.1, y: size * 0.1)
          }
          .fontWeight(.bold)
          .frame(width: size * 0.6)
        }
        .shadow(radius: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
  }
}

#Preview {
  IconPreview {
    WindowSwitcherIconView(size: $0)
  }
}
