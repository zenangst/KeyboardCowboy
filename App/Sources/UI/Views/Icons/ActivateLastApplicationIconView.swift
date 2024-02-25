import SwiftUI

struct ActivateLastApplicationIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(Color(nsColor: .systemPink))
      .overlay { iconOverlay().opacity(0.5) }
      .overlay { iconBorder(size) }
      .overlay(alignment: .center) {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .white), location: 0.35),
          .init(color: Color(nsColor: .systemPink.blended(withFraction: 0.2, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
        .mask {
          ZStack {
            Image(systemName: "app")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: size * 0.7)
            Image(systemName: "arrowshape.turn.up.backward.fill")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: size * 0.35)
              .offset(x: -size * 0.015, y: -size * 0.015)
          }
        }
        .shadow(color: Color(nsColor: .systemPink.blended(withFraction: 0.4, of: .black)!), radius: 2, y: 1)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    ActivateLastApplicationIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      ActivateLastApplicationIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        ActivateLastApplicationIconView(size: 64)
        ActivateLastApplicationIconView(size: 32)
        ActivateLastApplicationIconView(size: 16)
      }
    }
  }
  .padding()
}

