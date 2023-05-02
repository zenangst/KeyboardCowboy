import SwiftUI

struct GradientButtonStyle: ButtonStyle {
  struct GradientConfiguration {
    let cornerRadius: CGFloat
    let nsColor: NSColor
    let padding: Double
    let grayscaleEffect: Bool
    let hoverEffect: Bool

    internal init(nsColor: NSColor, cornerRadius: CGFloat = 4,
                  padding: Double = 4,
                  grayscaleEffect: Bool = false,
                  hoverEffect: Bool = true) {
      self.nsColor = nsColor
      self.cornerRadius = cornerRadius
      self.padding = padding
      self.grayscaleEffect = grayscaleEffect
      self.hoverEffect = hoverEffect
    }
  }

  @ObserveInjection var inject
  @State private var isHovered: Bool
  @Environment(\.colorScheme) var colorScheme

  private let config: GradientConfiguration

  init(_ config: GradientConfiguration) {
    self.config = config
    _isHovered = .init(initialValue: config.hoverEffect ? false : true)
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.vertical, config.padding)
      .padding(.horizontal, config.padding * 1.5)
      .foregroundColor(Color(.textColor))
      .background(
        RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
          .fill(
            LinearGradient(stops: [
              .init(color: Color(config.nsColor), location: 0.0),
              .init(color: Color(config.nsColor.blended(withFraction: 0.3, of: .black)!), location: 0.025),
              .init(color: Color(config.nsColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
          )
          .opacity(isHovered ? 1.0 : 0.3)
      )
      .background(
        RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
          .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1)
          .offset(y: 0.25)
      )
      .grayscale(config.grayscaleEffect ? isHovered ? 0 : 1 : 0)
      .compositingGroup()
      .shadow(color: Color.black.opacity(isHovered ? 0.5 : 0),
              radius: configuration.isPressed ? 0 : isHovered ? 1 : 1.25,
              y: configuration.isPressed ? 0 : isHovered ? 2 : 3)
      .opacity(configuration.isPressed ? 0.7 : isHovered ? 1.0 : 0.8)
      .offset(y: configuration.isPressed ? 0.25 : 0.0)
      .rotation3DEffect(.degrees(configuration.isPressed ? 2 : 0), axis: (x: 1.0, y: 0, z: 0))
      .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
      .animation(.easeOut(duration: 0.2), value: isHovered)
      .onHover(perform: { value in
        guard config.hoverEffect else { return }
        self.isHovered = value
      })
    }
}

struct GradientButtonStyle_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Button("Hello, world", action: {})
      Button("Hello, world", action: {})
        .buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen, hoverEffect: false)))
      Button("Hello, world", action: {})
        .buttonStyle(GradientButtonStyle(.init(nsColor: .systemBlue, hoverEffect: false)))
    }
    .padding()
  }
}
