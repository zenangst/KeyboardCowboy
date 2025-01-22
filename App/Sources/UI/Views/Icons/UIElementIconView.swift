import Inject
import SwiftUI

struct UIElementIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(.systemBlue))
      .overlay { UIElementIconGradientView() }
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay(alignment: .center) {
        UIElementIconViewFinderView(size)
        UIElementIconEllipsisView(size)
      }
    .compositingGroup()
    .frame(width: size, height: size)
    .fixedSize()
    .iconShape(size)
  }
}

struct UIElementIconGradientView: View {
  var body: some View {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(.systemRed).opacity(0.75), location: 0.0),
        .init(color: .clear, location: 0.75),
      ]),
      startPoint: .topTrailing,
      endPoint: .bottomLeading
    )

    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(.systemGreen), location: 0.0),
        .init(color: .clear, location: 0.5),
      ]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )

    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(.systemYellow).opacity(0.75), location: 0.0),
        .init(color: .clear, location: 0.4),
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(.systemPink).opacity(0.4), location: 0.0),
        .init(color: .clear, location: 1.0),
      ]),
      startPoint: .trailing,
      endPoint: .leading
    )
  }
}

private struct UIElementIconEllipsisView: View {
  private let size: CGFloat

  init(_ size: CGFloat) {
    self.size = size
  }

  var body: some View {
    Image(systemName: "ellipsis.rectangle.fill")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .foregroundStyle(
        .black.opacity(0.4),
        LinearGradient(stops: [
          .init(color: Color(nsColor: .systemYellow.withSystemEffect(.deepPressed)), location: 0.0),
          .init(color: Color(.systemYellow), location: 0.3),
          .init(color: Color(.systemOrange), location: 0.6),
          .init(color: Color(.systemRed), location: 1.0),
        ], startPoint: .top, endPoint: .bottomTrailing))
      .shadow(radius: 5)
      .frame(width: size * 0.64, height: size * 0.64)
      .offset(x: size * 0.0125)
  }
}

private struct UIElementIconViewFinderView: View {
  private let size: CGFloat

  init(_ size: CGFloat) {
    self.size = size
  }

  var body: some View {
    Image(systemName: "viewfinder")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .fontWeight(.light)
      .opacity(0.3)
      .shadow(radius: 10)
      .frame(width: size * 0.9, height: size * 0.9)
      .offset(x: size * 0.0125)
  }
}

#Preview {
  IconPreview { UIElementIconView(size: $0) }
}

