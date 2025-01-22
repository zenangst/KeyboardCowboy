import SwiftUI

struct MissionControlIconView: View {
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(Color(nsColor: .systemIndigo))
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .overlay(alignment: .center, content: {
        HStack(spacing: size * 0.03) {
          VStack(alignment: .trailing, spacing: size * 0.08) {
            MissionControlWindowView(.init(width: size * 0.28, height: size * 0.35))
              .opacity(0.75)
            MissionControlWindowView(.init(width: size * 0.2, height: size * 0.25))
              .opacity(0.2)
          }
          VStack(spacing: size * 0.09) {
            MissionControlWindowView(.init(width: size * 0.3, height: size * 0.25))
              .opacity(0.9)
            MissionControlWindowView(.init(width: size * 0.32, height: size * 0.315))
              .opacity(0.5)
          }
          VStack(alignment: .leading, spacing: size * 0.04) {
            MissionControlWindowView(.init(width: size * 0.26, height: size * 0.35))
              .opacity(0.7)
          }
        }
        .shadow(radius: 3)
      })
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

fileprivate struct MissionControlWindowView: View {
  private let size: CGSize

  init(_ size: CGSize) {
    self.size = size
  }

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .white), location: 0.0),
          .init(color: Color(nsColor: .white.withSystemEffect(.disabled)), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
      )
      .overlay(alignment: .topLeading) {
        HStack(alignment: .top, spacing: 0) {
          HStack(alignment: .top, spacing: size.width * 0.0_240) {
            Circle()
              .fill(Color(.systemRed))
            Circle()
              .fill(Color(.systemYellow))
            Circle()
              .fill(Color(.systemGreen))
            Divider()
              .frame(width: 1)
          }
          .frame(width: size.width * 0.3)
          .padding([.leading, .top], size.width * 0.0675)
          Rectangle()
            .fill(.white.opacity(0.7))
            .overlay { iconOverlay().opacity(0.5) }
            .frame(maxWidth: .infinity)
        }
      }
      .overlay { iconOverlay().opacity(0.5) }
      .overlay { iconBorder(size.width * 0.7) }
      .iconShape(size.width * 0.7)
      .frame(width: size.width, height: size.height)

  }
}

#Preview {
  IconPreview { MissionControlIconView(size: $0) }
}
