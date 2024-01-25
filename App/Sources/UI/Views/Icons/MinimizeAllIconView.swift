import SwiftUI

struct MinimizeAllIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(nsColor: .systemBrown))
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
      .overlay {
        window(.init(width: (size * 0.85) * 0.8,
                     height: (size * 0.75) * 0.8))
        .offset(y: -size * 0.1)
        .shadow(radius: 2)


        window(.init(width: (size * 0.85) * 0.9,
                     height: (size * 0.75) * 0.9))
        .offset(y: -size * 0.025)
        .shadow(radius: 2)

        window(.init(width: size * 0.85, height: size * 0.75))
          .offset(y: size * 0.05)
          .shadow(radius: 2)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }

  func window(_ size: CGSize) -> some View {
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
        }
      }
      .iconShape(size.width * 0.7)
      .frame(width: size.width, height: size.height)
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
