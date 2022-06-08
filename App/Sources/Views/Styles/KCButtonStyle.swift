import SwiftUI

struct KCButtonStyle: ButtonStyle {
  @Environment(\.colorScheme) var colorScheme

  func makeBody(configuration: Configuration) -> some View {
    KCButtonStyle
      .modifiers(configuration.label)
      .opacity(configuration.isPressed ? 0.8 : 1.0)
      .background(gradient)

  }

  private var gradient: some View {
    LinearGradient(
      gradient: Gradient(
        stops:
          colorScheme == .dark
        ? [.init(color: Color(.gridColor).opacity(0.25), location: 0.33),
           .init(color: Color(.gridColor).opacity(0.4), location: 1.0)]
        : [.init(color: Color(.textBackgroundColor).opacity(1), location: 0.0),
           .init(color: Color(.textBackgroundColor).opacity(0.75), location: 1.0)]
      ),
      startPoint: .top,
      endPoint: .bottom)
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

