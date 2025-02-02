import Bonzai
import Foundation
import SwiftUI

struct CommandLineIconView: View {
  let size: CGFloat

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(nsColor: .windowBackgroundColor.withSystemEffect(.disabled)), location: 0),
            .init(color: Color(nsColor: .windowBackgroundColor.blended(withFraction: 0.4, of: .black)!), location: 1.0)
          ],
          startPoint: .top,
          endPoint: .bottom)
      )
      .overlay { iconOverlay().opacity(0.25) }
      .overlay {
        VStack(spacing: size * 0.0_6) {
          let cornerRadius = size * 0.045

          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.clear))
            .overlay(alignment: .leading) {
              HStack(spacing: size * 0.05) {
                Text(">")
                  .font(.system(size: size * 0.095, weight: .heavy, design: .monospaced))
                  .padding(.leading, size * 0.05)
                RoundedRectangle(cornerRadius: cornerRadius)
                  .fill(
                    LinearGradient(stops: [
                      .init(color: .white.opacity(0.7), location: 0),
                      .init(color: .white.opacity(0.2), location: 0.8)
                    ], startPoint: .leading, endPoint: .trailing)
                  )
                  .frame(width: size * 0.5, height: size * 0.05, alignment: .leading)
              }
              .shadow(color: Color(nsColor: .controlAccentColor.blended(withFraction: 0.5, of: .white)!),radius: 5, y: 2)
            }
            .frame(width: size * 0.8, height: size * 0.15, alignment: .leading)
            .roundedStyle(cornerRadius, padding: 0)

          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.controlAccentColor))
            .overlay {
              LinearGradient(stops: [
                .init(color: Color(nsColor: .controlAccentColor), location: 0.2),
                .init(color: Color(nsColor: .controlAccentColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            }
            .frame(width: size * 0.8, height: size * 0.125)
            .roundedStyle(cornerRadius, padding: 0)

          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.windowBackgroundColor).opacity(0.5))
            .frame(width: size * 0.8, height: size * 0.125)
            .roundedStyle(cornerRadius, padding: 0)

          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.windowBackgroundColor).opacity(0.3))
            .frame(width: size * 0.8, height: size * 0.125)
            .roundedStyle(cornerRadius, padding: 0)
        }
      }
      .overlay(alignment: .topTrailing) {
        Rectangle()
          .fill(
            LinearGradient(stops: [
              .init(color: Color(.systemYellow.withSystemEffect(.rollover)), location: 0),
              .init(color: Color(.systemYellow), location: 0.5),
            ], startPoint: .top, endPoint: .bottom)
          )
          .frame(width: size * 0.7, height: size * 0.2)
          .offset(x: size * 0.2, y: -size * 0.1)
          .rotationEffect(.degrees(45))
      }
      .overlay { iconBorder(size) }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  IconPreview(content: { CommandLineIconView(size: $0) })
}
