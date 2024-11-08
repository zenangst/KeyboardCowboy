import SwiftUI

struct WorkflowBadge: View {
  @Binding private var isHovered: Bool
  private let text: String
  private let badgeOpacity: Double

  init(isHovered: Binding<Bool>, text: String, badgeOpacity: Double) {
    self._isHovered = isHovered
    self.text = text
    self.badgeOpacity = badgeOpacity
  }

  var body: some View {
    Text(text)
      .aspectRatio(1, contentMode: .fill)
      .padding(1)
      .lineLimit(1)
      .minimumScaleFactor(0.5)
      .allowsTightening(true)
      .bold()
      .font(.caption2)
      .padding(2)
      .background(
        Circle()
          .fill(Color.accentColor)
      )
      .frame(maxWidth: 12)
      .compositingGroup()
      .shadow(color: .black.opacity(0.75), radius: 2)
      .opacity(isHovered ? badgeOpacity : 0)
      .animation(.default, value: isHovered)
  }
}

