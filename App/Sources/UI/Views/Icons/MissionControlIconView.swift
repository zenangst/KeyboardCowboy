import SwiftUI

struct MissionControlIconView: View {
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(Color(nsColor: .systemPurple.withSystemEffect(.disabled)))
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
      .overlay(alignment: .center, content: {
        HStack(spacing: size * 0.03) {
          VStack(alignment: .trailing, spacing: size * 0.08) {
            window(.init(width: size * 0.28, height: size * 0.35))
              .opacity(0.75)
            window(.init(width: size * 0.2, height: size * 0.25))
              .opacity(0.2)
          }
          VStack(spacing: size * 0.09) {
            window(.init(width: size * 0.3, height: size * 0.25))
              .opacity(0.9)
            window(.init(width: size * 0.32, height: size * 0.315))
              .opacity(0.5)
          }
          VStack(alignment: .leading, spacing: size * 0.04) {
            window(.init(width: size * 0.26, height: size * 0.35))
              .opacity(0.7)
          }
        }
        .shadow(radius: 3)
      })
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }

  func window(_ size: CGSize) -> some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemPurple.withSystemEffect(.pressed)), location: 0.0),
          .init(color: Color(nsColor: .systemPurple.withSystemEffect(.disabled)), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)

      )
      .iconShape(size.width * 0.7)
      .frame(width: size.width, height: size.height)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    MissionControlIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      MissionControlIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        MissionControlIconView(size: 64)
        MissionControlIconView(size: 32)
        MissionControlIconView(size: 16)
      }
    }
  }
  .padding()
}
