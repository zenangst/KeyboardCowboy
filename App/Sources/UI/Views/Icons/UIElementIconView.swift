import Inject
import SwiftUI

struct UIElementIconView: View {
  let size: CGFloat

  @ObserveInjection var inject
  var body: some View {
    Rectangle()
      .fill(Color(.systemBlue))
      .overlay {
        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(.systemRed).opacity(0.75), location: 0.0),
                .init(color: .clear, location: 0.75),
              ]),
              startPoint: .topTrailing,
              endPoint: .bottomLeading
            )
          )

        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(.systemGreen), location: 0.0),
                .init(color: .clear, location: 0.5),
              ]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )

        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(.systemYellow).opacity(0.75), location: 0.0),
                .init(color: .clear, location: 0.4),
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )

        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(.systemPink).opacity(0.4), location: 0.0),
                .init(color: .clear, location: 1.0),
              ]),
              startPoint: .trailing,
              endPoint: .leading
            )
          )
      }
      .overlay {
        Image(systemName: "viewfinder")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .opacity(0.3)
          .padding(2)
          .shadow(radius: 1)
          .mask(alignment: .center, {
            LinearGradient(stops: [
              .init(color: .black.opacity(0.5), location: 0.2),
              .init(color: .black.opacity(0.8), location: 0.75)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
          })

      }
      .overlay {
        Image(systemName: "ellipsis.rectangle.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding(6)
          .shadow(radius: 1)
          .mask(alignment: .center, {
            LinearGradient(stops: [
              .init(color: .black, location: 0.0),
              .init(color: .clear, location: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)

          })
          .opacity(0.5)
      }
    .compositingGroup()
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .frame(width: size, height: size)
    .fixedSize()
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
  let canvas = CGSize(width: 32, height: 32)
  return UIElementIconView(size: canvas.width)
    .frame(width: canvas.width, height: canvas.height)
    .padding()
}

