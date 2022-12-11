import SwiftUI

struct KCButtonStyle: ButtonStyle {
  @ObserveInjection var inject
  @State private var isHovered = false
  @Environment(\.colorScheme) var colorScheme

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(4)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(.controlColor))
            .opacity( isHovered ? 0.8 : 0.25)
        }
      )
      .foregroundColor(
        Color(.labelColor)
      )
      .font(.system(.caption2, design: .rounded, weight: .semibold))
      .opacity(configuration.isPressed ? 0.6 : isHovered ? 1.0 : 0.8)
      .offset(y: configuration.isPressed ? 0.25 : 0.0)
//      .background(gradient.cornerRadius(8))
      .shadow(radius: configuration.isPressed ? 0 : isHovered ? 1 : 2)
      .onHover(perform: { value in
        self.isHovered = value
      })
      .animation(.linear(duration: 0.1), value: isHovered)
      .enableInjection()
  }

  private var gradient: some View {
    LinearGradient(
      gradient: Gradient(
        stops:
          colorScheme == .dark
        ? [
          .init(color: Color(.windowBackgroundColor).opacity(0.5), location: 0.5),
          .init(color: Color(.gridColor).opacity(0.75), location: 1.0
                )]
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

