import SwiftUI

struct WindowTidyIcon: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.6, of: .white)!), location: 0.3),
          .init(color: Color(.cyan), location: 0.6),
          .init(color: Color.blue, location: 1.0),
        ], startPoint: .bottomTrailing, endPoint: .topLeading)
      )
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemPurple.blended(withFraction: 0.3, of: .white)!), location: 0.5),
          .init(color: Color.blue, location: 1.0),
        ], startPoint: .topTrailing, endPoint: .bottomTrailing)
        .opacity(0.6)
        .rotationEffect(.degrees(180))
      }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(.systemOrange.blended(withFraction: 0.3, of: .white)!), location: 0.2),
          .init(color: Color.clear, location: 0.8),
        ], startPoint: .topTrailing, endPoint: .bottomLeading)
        .rotationEffect(.degrees(180))
      }
      .overlay {
        WindowsGridView(size: size)
      }
      .overlay { iconOverlay().opacity(0.65) }
      .overlay { iconBorder(size) }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
      .drawingGroup()
  }
}

fileprivate struct WindowsGridView: View {
  let size: CGFloat

  var body: some View {
    VStack(spacing: size * 0.075) {
      HStack(spacing: size * 0.075) {
        WindowTidyIconIllustrationApp(size: size * 0.38)
        WindowTidyIconIllustrationApp(size: size * 0.38)
      }
      .overlay(alignment: .center) {
        ZStack {
          BlurredElement(blurRadius: 0, stops: [
            .init(color: .white, location: 0.25),
            .init(color: .clear, location: 0.5),
          ], size: size * 1.1)
          .rotationEffect(.degrees(-45))
          .offset(x: -size * 0.23, y: size * 0.025)
          .shadow(color: Color(.systemGreen).opacity(0.8), radius: 24,
                  x: -size * 0.025, y: size * 0.025)

          BlurredElement(blurRadius: 1, stops: [
            .init(color: .white, location: 0),
            .init(color: .clear, location: 1),
          ], size: size * 0.8)
          .rotationEffect(.degrees(-45))
          .offset(x: -size * 0.23, y: size * 0.025)
          .shadow(color: Color(.systemGreen).opacity(0.8), radius: 24,
                  x: -size * 0.025, y: size * 0.025)

          BlurredElement(blurRadius: 0, stops: [
            .init(color: .white, location: 0.25),
            .init(color: .clear, location: 0.5),
          ], size: size * 1.1)
          .rotationEffect(.degrees(45))
          .offset(x: size * 0.23, y: size * 0.025)
          .shadow(color: Color(.systemCyan).opacity(0.8), radius: 24,
                  x: size * 0.025, y: size * 0.025)

          BlurredElement(blurRadius: 1, stops: [
            .init(color: .white, location: 0),
            .init(color: .clear, location: 1),
          ], size: size * 0.8)
          .rotationEffect(.degrees(45))
          .offset(x: size * 0.23, y: size * 0.025)
          .shadow(color: Color(.systemCyan).opacity(0.8), radius: 24,
                  x: size * 0.025, y: size * 0.025)

        }
      }
      .clipped()

      HStack(spacing: size * 0.075) {
        WindowTidyIconIllustrationApp(size: size * 0.38)
        WindowTidyIconIllustrationApp(size: size * 0.38)
      }
      .overlay(alignment: .center) {
        ZStack {
          BlurredElement(blurRadius: 0, stops: [
            .init(color: .white, location: 0.25),
            .init(color: .clear, location: 0.5),
          ], size: size * 1.1)
          .rotationEffect(.degrees(-135))
          .offset(x: -size * 0.23, y: size * 0.015)
          .shadow(color: Color(.systemPink).opacity(0.8), radius: 24,
                  x: size * 0.025, y: -size * 0.025)

          BlurredElement(blurRadius: 1, stops: [
            .init(color: .white, location: 0),
            .init(color: .clear, location: 1),
          ], size: size * 0.8)
          .rotationEffect(.degrees(-135))
          .offset(x: -size * 0.23, y: size * 0.015)
          .shadow(color: Color(.systemPink).opacity(0.8), radius: 24,
                  x: size * 0.025, y: -size * 0.025)

          BlurredElement(blurRadius: 0, stops: [
            .init(color: .white, location: 0.25),
            .init(color: .clear, location: 0.5),
          ], size: size * 1.1)
          .rotationEffect(.degrees(135))
          .offset(x: size * 0.23, y: size * 0.015)
          .shadow(color: Color(.systemOrange).opacity(0.8), radius: 24,
                  x: size * 0.025, y: -size * 0.025)

          BlurredElement(blurRadius: 1, stops: [
            .init(color: .white, location: 0),
            .init(color: .clear, location: 1),
          ], size: size * 0.8)
          .rotationEffect(.degrees(135))
          .offset(x: size * 0.23, y: size * 0.015)
          .shadow(color: Color(.systemOrange).opacity(0.8), radius: 24,
                  x: size * 0.025, y: -size * 0.025)
        }
      }
      .clipped()

    }
    .mask {
      LinearGradient(stops: [
        .init(color: .black.opacity(0.5), location: 0),
        .init(color: .black, location: 1)
      ], startPoint: .top, endPoint: .bottom)
    }
  }
}

struct BlurredElement: View {
  let blurRadius: CGFloat
  let stops: [Gradient.Stop]
  let size: CGFloat

  var body: some View {
    RoundedRectangle(cornerRadius: size * 0.1)
      .fill(
        LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
      )
      .frame(width: size * 0.15, height: size * 0.3)
      .blur(radius: blurRadius)
  }
}

struct WindowTidyIconGroupView: View {
  let size: CGFloat
  var body: some View {
    Group {
      ZStack {
        WindowTidyIconIllustrationApp(size: size * 0.5)
          .mask {
            LinearGradient(stops: [
              .init(color: .black.opacity(0.6), location: 0),
              .init(color: .clear, location: 0.5)
            ], startPoint: .top, endPoint: .bottom)
          }
          .offset(y: -size * 0.145)

        WindowTidyIconIllustrationApp(size: size * 0.6)
          .mask {
            LinearGradient(stops: [
              .init(color: .black.opacity(0.6), location: 0),
              .init(color: .clear, location: 0.5)
            ], startPoint: .top, endPoint: .bottom)
          }
          .offset(y: -size * 0.055)
        WindowTidyIconIllustrationApp(size: size * 0.65)
          .offset(y: size * 0.015)
      }
    }
    .compositingGroup()
    .shadow(radius: 2, y: 2)
    .frame(width: size / 1.25, height: size / 1.25)
  }
}

struct WindowTidyIconIllustrationApp: View {
  let size: CGFloat

  init(size: CGFloat) {
    self.size = size
  }
  var body: some View {
    Image(systemName: "app.fill")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: size, height: size)
      .fontWeight(.light)
      .overlay(alignment: .top) {
        RoundedRectangle(cornerRadius: size * 0.2)
          .fill(Color.white.opacity(0.3))
          .frame(width: size, height: size * 0.15)
          .overlay {
            HStack(spacing: size * 0.05) {
              Circle()
                .stroke(Color.white, lineWidth: size * 0.02)
              Circle()
                .stroke(Color.white, lineWidth: size * 0.02)
              Circle()
                .stroke(Color.white, lineWidth: size * 0.02)
              Spacer()
            }
            .padding(.leading, size * 0.125)
            .frame(height: size * 0.05)
          }
      }
      .mask {
        LinearGradient(
          stops: [.init(color: .black, location: 0.25),
                  .init(color: .black.opacity(0.5), location: 1)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
      .mask {
        Image(systemName: "app.fill")
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
  }
}

#Preview {
  IconPreview { WindowTidyIcon(size: $0) }
}
