import SwiftUI

struct GradientConfiguration {
  let cornerRadius: CGFloat
  let nsColor: NSColor
  let padding: Padding
  let grayscaleEffect: Bool
  let hoverEffect: Bool

  struct Padding {
    let horizontal: CGFloat
    let vertical: CGFloat?
  }

  internal init(nsColor: NSColor, cornerRadius: CGFloat = 4,
                padding: Padding = .init(horizontal: 4, vertical: 4),
                grayscaleEffect: Bool = false,
                hoverEffect: Bool = true) {
    self.nsColor = nsColor
    self.cornerRadius = cornerRadius
    self.padding = padding
    self.grayscaleEffect = grayscaleEffect
    self.hoverEffect = hoverEffect
  }
}

struct GradientButtonStyle: ButtonStyle {

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
      .padding(.vertical, config.padding.vertical)
      .padding(.horizontal, config.padding.horizontal * 1.5)
      .foregroundColor(Color(.textColor))
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            .fill(
              LinearGradient(stops: [
                .init(color: Color(config.nsColor), location: 0.0),
                .init(color: Color(config.nsColor.blended(withFraction: 0.3, of: .black)!), location: 0.025),
                .init(color: Color(config.nsColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
            .opacity(isHovered ? 1.0 : 0.3)
          RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1)
            .offset(y: 0.25)
        }
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

struct GradientMenuStyle: MenuStyle {
  private let config: GradientConfiguration
  private let fixedSize: Bool
  private let menuIndicator: Visibility
  @State private var isHovered: Bool

  init(_ config: GradientConfiguration,
       fixedSize: Bool = true,
       menuIndicator: Visibility = .visible) {
    self.config = config
    self.fixedSize = fixedSize
    self.menuIndicator = menuIndicator
    _isHovered = .init(initialValue: config.hoverEffect ? false : true)
  }

  func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .font(.caption)
      .truncationMode(.middle)
      .allowsTightening(true)
      .menuStyle(.borderlessButton)
      .menuIndicator(menuIndicator)
      .foregroundColor(Color(.textColor))
      .padding(.horizontal, config.padding.horizontal)
      .padding(.vertical, config.padding.vertical)
      .frame(minHeight: 24)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            .fill(
              LinearGradient(stops: [
                .init(color: Color(config.nsColor), location: 0.0),
                .init(color: Color(config.nsColor.blended(withFraction: 0.3, of: .black)!), location: 0.025),
                .init(color: Color(config.nsColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
            .opacity(isHovered ? 1.0 : 0.3)
          RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1)
            .offset(y: 0.25)
        }
      )
      .grayscale(config.grayscaleEffect ? isHovered ? 0 : 1 : 0)
      .compositingGroup()
      .shadow(color: Color.black.opacity(isHovered ? 0.5 : 0),
              radius: isHovered ? 1 : 1.25,
              y: isHovered ? 2 : 3)
      .opacity(isHovered ? 1.0 : 0.8)
      .animation(.easeOut(duration: 0.2), value: isHovered)
      .onHover(perform: { value in
        guard config.hoverEffect else { return }
        self.isHovered = value
      })
      .fixedSize(horizontal: fixedSize, vertical: true)
      .contentShape(Rectangle())
  }
}
