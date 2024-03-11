import SwiftUI

struct KeyBackgroundView: View {
  @Environment(\.colorScheme) var colorScheme
  @Binding var isPressed: Bool
  let height: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color(.textBackgroundColor))
      .overlay { iconOverlay().opacity(0.2) }
      .overlay { iconBorder(height) }
      .overlay {
        AngularGradient(stops: [
          .init(color: Color.clear, location: 0.0),
          .init(color: Color.white.opacity(0.2), location: 0.2),
          .init(color: Color.clear, location: 1.0),
        ], center: .bottomLeading)

        LinearGradient(stops: [
          .init(color: Color.white.opacity(0.1), location: 0),
          .init(color: Color.clear, location: 0.02),
        ], startPoint: .top, endPoint: .bottom)

        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.99),
          .init(color: Color(.windowBackgroundColor), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)
      }
      .drawingGroup(opaque: true)
      .iconShape(height * 0.8)
  }
}

struct KeyBackground_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      ModifierKeyIcon_Previews.previews
      RegularKeyIcon_Previews.previews
    }
  }
}
