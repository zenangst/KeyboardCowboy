import SwiftUI

struct MinimizeAllIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(nsColor: .systemBrown))
      .overlay { iconOverlay() }
      .overlay { iconBorder(size) }
      .overlay {
        MinimizeAllWindowView(.init(width: (size * 0.85) * 0.8,
                     height: (size * 0.75) * 0.8))
        .offset(y: -size * 0.1)
        .shadow(radius: 2)


        MinimizeAllWindowView(.init(width: (size * 0.85) * 0.9,
                     height: (size * 0.75) * 0.9))
        .offset(y: -size * 0.025)
        .shadow(radius: 2)

        MinimizeAllWindowView(.init(width: size * 0.85, height: size * 0.75))
          .offset(y: size * 0.05)
          .shadow(radius: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

private struct MinimizeAllWindowView: View {
  let size: CGSize

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
      .overlay { iconOverlay().opacity(0.5) }
      .overlay(alignment: .topLeading) {
        HStack(alignment: .top, spacing: 0) {
          MinimizeAllWindowTrafficLightsView(size)
          Rectangle()
            .fill(.white)
            .frame(maxWidth: .infinity)
            .overlay {
              Image(systemName: "arrow.down")
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

private struct MinimizeAllWindowTrafficLightsView: View {
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
            .opacity(0.8)
            .frame(width: size.width * 0.06)
        }
      Circle()
        .fill(Color(.systemGreen))
        .grayscale(0.5)
      Divider()
        .frame(width: 1)
    }
    .frame(width: size.width * 0.4)
    .padding([.leading, .top], size.width * 0.0675)

  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    MinimizeAllIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      MinimizeAllIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        MinimizeAllIconView(size: 64)
        MinimizeAllIconView(size: 32)
        MinimizeAllIconView(size: 16)
      }
    }
  }
  .padding()
}
