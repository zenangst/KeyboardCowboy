import SwiftUI

struct KCButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    KCButtonStyle
      .modifiers(configuration.label)
      .opacity(configuration.isPressed ? 0.8 : 1.0)
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

