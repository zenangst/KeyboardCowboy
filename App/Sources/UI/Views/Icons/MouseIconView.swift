import SwiftUI

struct MouseIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(Color(.systemGreen))
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay {
        Capsule()
          .fill(Color(.white))
          .frame(width: size * 0.45, height: size * 0.8)
          .shadow(radius: 2, y: 2)
      }
      .overlay(alignment: .top) {
        Capsule()
          .fill(
            Color(.systemGray),
          )
          .overlay {
            LinearGradient(stops: [
              .init(color: Color.white.opacity(0.0), location: 0),
              .init(color: Color.white.opacity(0.5), location: 0.5),
              .init(color: Color.clear, location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
          }
          .frame(width: size * 0.03, height: size * 0.04)
          .offset(y: size * 0.23)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  IconPreview { MouseIconView(size: $0) }
}
