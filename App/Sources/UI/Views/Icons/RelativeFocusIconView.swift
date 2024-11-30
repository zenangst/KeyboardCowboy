import SwiftUI

struct RelativeFocusIconView: View {
  enum Kind {
    case up, down, left, right,
         upperLeft, upperRight,
         lowerLeft, lowerRight,
         center
    var systemName: String {
      switch self {
      case .upperLeft: "arrow.up.left"
      case .upperRight: "arrow.up.right"
      case .lowerLeft: "arrow.down.left"
      case .lowerRight: "arrow.down.right"
      case .up:    "arrow.up"
      case .down:  "arrow.down"
      case .left:  "arrow.left"
      case .right: "arrow.right"
      case .center: "rectangle.center.inset.filled"
      }
    }
  }
  let kind: Kind
  let size: CGFloat

  init(_ kind: Kind, size: CGFloat) {
    self.kind = kind
    self.size = size
  }

  var body: some View {
    Rectangle()
      .fill(Color(nsColor: .systemPink))
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay {
        WindowView(.init(width: (size * 0.85) * 0.9, height: (size * 0.85) * 0.9),
                   image: Image(systemName: kind.systemName))
        .shadow(radius: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
  }
}

private struct WindowView: View {
  let size: CGSize
  private let image: Image

  init(_ size: CGSize, image: Image) {
    self.size = size
    self.image = image
  }

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(nsColor: .white), location: 0.0),
          .init(color: Color(nsColor: .white.withSystemEffect(.disabled)), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.5) }
      .overlay(alignment: .topLeading) {
        HStack(alignment: .top, spacing: 0) {
          TrafficLightsView(size)
          Rectangle()
            .fill(.white)
            .frame(maxWidth: .infinity)
            .overlay {
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fontWeight(.heavy)
                .foregroundStyle(Color.accentColor)
                .opacity(0.4)
                .frame(width: size.width * 0.3)
            }
            .overlay { iconOverlay().opacity(0.5) }
        }
      }
      .iconShape(size.width * 0.7)
      .frame(width: size.width, height: size.height)
      .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
  }
}

private struct TrafficLightsView: View {
  let size: CGSize

  init(_ size: CGSize) {
    self.size = size
  }

  var body: some View {
    HStack(alignment: .top, spacing: size.width * 0.0_240) {
      Circle()
        .fill(Color(.systemRed))
        .grayscale(0.5)
      Circle()
        .fill(Color(.systemYellow))
        .shadow(color: Color(.systemYellow), radius: 10)
        .overlay(alignment: .center) {
          Image(systemName: "minus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fontWeight(.heavy)
            .foregroundStyle(Color.orange)
            .opacity(0.9)
            .frame(width: size.width * 0.06)
        }
      Circle()
        .fill(Color(.systemGreen))
        .grayscale(0.5)
      Divider()
        .frame(width: 1)
    }
    .frame(width: size.width * 0.3)
    .padding([.leading, .top], size.width * 0.0675)

  }
}

#Preview("Up") {
  IconPreview { RelativeFocusIconView(.up, size: $0) }
}

#Preview("Upper Left") {
  IconPreview { RelativeFocusIconView(.upperLeft, size: $0) }
}
