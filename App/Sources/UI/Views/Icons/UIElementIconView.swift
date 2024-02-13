import Inject
import SwiftUI

struct UIElementIconView: View {
  let size: CGFloat

  @ObserveInjection var inject
  var body: some View {
    Rectangle()
      .fill(Color(.systemBlue))
      .overlay {
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
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay(alignment: .center) {
        Image(systemName: "viewfinder")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .fontWeight(.light)
          .opacity(0.3)
          .shadow(radius: 10)
          .frame(width: size * 0.9, height: size * 0.9)
          .offset(x: size * 0.0125)

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
    .compositingGroup()
    .frame(width: size, height: size)
    .fixedSize()
    .iconShape(size)
    .enableInjection()
  }

  func mask() -> LinearGradient {
    LinearGradient(stops: [
      .init(color: .black, location: 0.0),
      .init(color: .clear, location: 1.0)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    UIElementIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      UIElementIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        UIElementIconView(size: 64)
        UIElementIconView(size: 32)
        UIElementIconView(size: 16)
      }
    }
  }
  .padding()
}

