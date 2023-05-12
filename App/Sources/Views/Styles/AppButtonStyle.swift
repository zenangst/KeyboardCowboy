import SwiftUI

enum AppButtonStyleEnum {
  case appStyle
  case saveStyle
  case destructiveStyle
  case gradientStyle(config: GradientButtonStyle.GradientConfiguration)
}

extension View {
  @ViewBuilder
  func buttonStyle(_ style: AppButtonStyleEnum) -> some View {
    switch style {
    case .appStyle:
      self.buttonStyle(AppButtonStyle())
    case .saveStyle:
      self.buttonStyle(GradientButtonStyle(.init(nsColor: .systemGreen)))
    case .destructiveStyle:
      self.buttonStyle(GradientButtonStyle(.init(nsColor: .systemRed)))
    case .gradientStyle(let config):
      self.buttonStyle(GradientButtonStyle(config))
    }
  }
}

struct AppButtonStyle: ButtonStyle {
  @State private var isHovered = false
  @Environment(\.colorScheme) var colorScheme

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(4)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.controlColor))
          .opacity( isHovered ? 0.8 : 0.25)
      )
      .foregroundColor(
        Color(.labelColor)
      )
      .font(.system(.body, design: .rounded, weight: .semibold))
      .opacity(configuration.isPressed ? 0.6 : isHovered ? 1.0 : 0.8)
      .offset(y: configuration.isPressed ? 0.25 : 0.0)
      .compositingGroup()
      .shadow(radius: configuration.isPressed ? 0 : isHovered ? 1 : 2)
      .onHover(perform: { value in
        self.isHovered <- value
      })
      .animation(.linear(duration: 0.1), value: isHovered)
    }

  static func modifiers<Content: View>(_ content: Content) -> some View {
    content
      .padding(6)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.controlColor))
        }
      )
      .foregroundColor(
        Color(.labelColor)
      )
      .buttonStyle(BorderlessButtonStyle())
  }
}

