import SwiftUI

struct SnippetIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(nsColor: .systemPink), location: 0.1),
            .init(color: Color(nsColor: .systemPink.withSystemEffect(.disabled)), location: 1.0)
          ],
          startPoint: .top,
          endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay { iconBorder(size) }
      .overlay {
        LinearGradient(stops: [
          .init(color: Color(nsColor: .white), location: 0.2),
          .init(color: Color(nsColor: .systemPink.blended(withFraction: 0.2, of: .white)!), location: 1.0),
        ], startPoint: .topLeading, endPoint: .bottom)
        .mask {
          Text("{}")
            .font(Font.system(size: size * 0.6, weight: .bold, design: .monospaced))
        }
        .shadow(color: Color(nsColor: .systemPink.blended(withFraction: 0.4, of: .black)!), radius: 2, y: 1)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  VStack {
    HStack(alignment: .top, spacing: 8) {
      SnippetIconView(size: 192)
      VStack(alignment: .leading, spacing: 8) {
        SnippetIconView(size: 128)
        HStack(alignment: .top, spacing: 8) {
          SnippetIconView(size: 64)
          SnippetIconView(size: 32)
          SnippetIconView(size: 16)
        }
      }
    }

    HStack(alignment: .top, spacing: 8) {
      SnippetIconView(size: 192)
      VStack(alignment: .leading, spacing: 8) {
        SnippetIconView(size: 128)
        HStack(alignment: .top, spacing: 8) {
          SnippetIconView(size: 64)
          SnippetIconView(size: 32)
          SnippetIconView(size: 16)
        }
      }
    }
  }
  .padding()
}
