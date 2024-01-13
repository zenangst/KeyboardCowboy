import Inject
import SwiftUI

struct MenuIconView: View {
  @ObserveInjection var inject
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(.systemYellow).opacity(0.65), location: 0.0),
            .init(color: Color(.systemBlue).opacity(0.65), location: 1.0),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .overlay(alignment: .top) {
        Rectangle()
          .fill(Color(.white).opacity(0.4))
          .frame(height: size * 0.2)
          .overlay(alignment: .leading) {
            VStack {
              Image(systemName: "apple.logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.black)
                .frame(height: size * 0.1)
            }
            .padding(.leading, size * 0.0_7)
          }
      }
      .overlay(alignment: .bottomTrailing) {
        Rectangle()
          .frame(width: size * 0.8, height: size * 0.6)
          .clipShape(TopLeadingRoundedShape(radius: size * 0.0_5))
          .overlay(alignment: .topLeading) {
            HStack(spacing: size * 0.0_50) {
              Circle()
                .fill(Color(.systemRed))
              Circle()
                .fill(Color(.systemYellow))
              Circle()
                .fill(Color(.systemGreen))
            }
            .shadow(radius: 0.5)
            .frame(height: size * 0.1)
            .padding([.top, .leading], size * 0.0_5)
          }
          .compositingGroup()
          .shadow(radius: 3, y: 3)
      }
      .overlay(alignment: .bottomTrailing) {
        Rectangle()
          .fill(Color(.black).opacity(0.15))
          .frame(width: size * 0.75, height: size * 0.25)
          .clipShape(TopLeadingRoundedShape(radius: size * 0.0_5))
      }
      .background(Color(.systemGray))
      .compositingGroup()
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .frame(width: size, height: size)
      .fixedSize()
      .enableInjection()
  }
}

struct TopLeadingRoundedShape: Shape {
  var radius: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let topRight = CGPoint(x: rect.maxX, y: rect.minY)
    let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
    let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

    path.move(to: bottomLeft)
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
    path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false)
    path.addLine(to: topRight)
    path.addLine(to: bottomRight)
    path.addLine(to: bottomLeft)

    return path
  }
}

#Preview {
  HStack {
    MenuIconView(size: 24)
    MenuIconView(size: 32)
    MenuIconView(size: 64)
    MenuIconView(size: 128)
  }
    .padding()
}
