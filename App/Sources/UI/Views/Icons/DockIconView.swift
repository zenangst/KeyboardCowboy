import SwiftUI

struct DockIconView: View {
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(Color(.controlAccentColor))
      .overlay {
        AngularGradient(stops: [
          .init(color: Color.clear, location: 0.0),
          .init(color: Color.white.opacity(0.2), location: 0.2),
          .init(color: Color.clear, location: 1.0),
        ], center: .bottomLeading)

        LinearGradient(stops: [
          .init(color: Color.white.opacity(0.2), location: 0),
          .init(color: Color.clear, location: 0.3),
        ], startPoint: .top, endPoint: .bottom)

        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.8),
          .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      }
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
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)

          Rectangle()
            .iconShape(size * 0.1)
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)

          Rectangle()
            .iconShape(size * 0.1)
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)

          Rectangle()
            .iconShape(size * 0.1)
            .frame(width: iconSize, height: iconSize)
            .offset(y: -size * 0.075)
        }
        .offset(y: -size * 0.075)
      })
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    DockIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      DockIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        DockIconView(size: 64) 
        DockIconView(size: 32)
        DockIconView(size: 16)
      }
    }
  }
  .padding()
}
