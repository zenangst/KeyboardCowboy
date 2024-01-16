import Inject
import SwiftUI

struct UIElementIconView: View {
  let size: CGFloat
  @Binding var stacked: Bool

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
      .overlay {
        Image(systemName: "viewfinder")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .fontWeight(.light)
          .opacity(0.3)
          .padding(2)
          .shadow(radius: 1)
          .mask(alignment: .center, {
            LinearGradient(stops: [
              .init(color: .black.opacity(0.5), location: 0.2),
              .init(color: .black.opacity(0.8), location: 0.75)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
          })
          .frame(width: size * 0.95)
          .shadow(radius: 10)
          .rotation3DEffect(
            .degrees(5), axis: (x: 1.0, y: 0.0, z: 0.0)
          )
      }
      .overlay {
        Image(systemName: "ellipsis.rectangle.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding(6)
          .shadow(radius: 1)
          .mask(alignment: .center, {
            LinearGradient(stops: [
              .init(color: .black, location: 0.5),
              .init(color: .clear, location: 1.0)
            ], startPoint: .top, endPoint: .bottomTrailing)
          })
          .opacity(0.5)
          .frame(width: size * 0.8)
          .rotation3DEffect(
            .degrees(17.5), axis: (x: 1.0, y: 0.0, z: 0.0)
          )
      }
    .compositingGroup()
    .clipShape(RoundedRectangle(cornerRadius: size * 0.125))
    .frame(width: size, height: size)
    .fixedSize()
    .stacked($stacked, color: Color(.systemPurple), size: size)
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
  VStack {
    HStack {
      UIElementIconView(size: 128, stacked: .constant(false))
     UIElementIconView(size: 64, stacked: .constant(false))
     UIElementIconView(size: 32, stacked: .constant(false))
    }
  }
  .padding()
}

