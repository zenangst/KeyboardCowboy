import SwiftUI

struct GradientButtonStyle: ButtonStyle {
  struct GradientConfiguration {
    let nsColor: NSColor
    let padding: Double
    let grayscaleEffect: Bool

    internal init(nsColor: NSColor, padding: Double = 4, grayscaleEffect: Bool = false) {
      self.nsColor = nsColor
      self.padding = padding
      self.grayscaleEffect = grayscaleEffect
    }
  }

  @State private var isHovered = false
  @Environment(\.colorScheme) var colorScheme

  private let config: GradientConfiguration

  init(_ config: GradientConfiguration) {
    self.config = config
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(config.padding)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(
              LinearGradient(stops: [
                .init(color: Color(config.nsColor), location: 0.0),
                .init(color: Color(config.nsColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
            .opacity(isHovered ? 1.0 : 0.3)
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(config.nsColor))
            .opacity(isHovered ? 0.4 : 0.1)
        }
      )
      .grayscale(config.grayscaleEffect ? isHovered ? 0 : 1 : 0)
      .foregroundColor(
        Color(.labelColor)
      )
      .shadow(color: Color.black.opacity(isHovered ? 0.7 : 0),
              radius: configuration.isPressed ? 0 : isHovered ? 1 : 2,
              y: configuration.isPressed ? 0 : isHovered ? 1 : 2)
      .font(.system(.body, design: .rounded, weight: .semibold))
      .opacity(configuration.isPressed ? 0.6 : isHovered ? 1.0 : 0.8)
      .offset(y: configuration.isPressed ? 0.25 : 0.0)
      .rotation3DEffect(.degrees(configuration.isPressed ? 0.5 : 0), axis: (x: 1.0, y: 0, z: 0))
      .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
      .animation(.easeOut(duration: 0.2), value: isHovered)
      .onHover(perform: { value in
        self.isHovered = value
      })
    }
}
