import SwiftUI

struct AddButtonView: View {
  @State private var isHovered = false

  let text: String
  let action: () -> Void
  let hoverEffectIsEnabled: Bool

  init(_ text: String,
       hoverEffectIsEnabled: Bool = true,
       action: @escaping () -> Void) {
    self.text = text
    self.action = action
    self.hoverEffectIsEnabled = hoverEffectIsEnabled
    _isHovered = .init(initialValue: hoverEffectIsEnabled ? false : true)
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 2) {
        Image(systemName: "plus.circle")
          .padding(2)
          .background(
            ZStack {
              RoundedRectangle(cornerRadius: 16)
                .fill(
                  LinearGradient(stops: [
                    .init(color: Color(.systemGreen), location: 0.0),
                    .init(color: Color(.systemGreen.blended(withFraction: 0.5, of: .black)!), location: 1.0),
                  ], startPoint: .top, endPoint: .bottom)
                )
                .opacity(isHovered ? 1.0 : 0.3)
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGreen))
                .opacity(isHovered ? 0.4 : 0.1)
            }
          )
          .grayscale(isHovered ? 0 : 1)
          .foregroundColor(
            Color(.labelColor)
          )
            .animation(.easeOut(duration: 0.2), value: isHovered)
        Text(text)
      }
    }
    .buttonStyle(.plain)
    .onHover(perform: { value in
      guard hoverEffectIsEnabled else { return }
      self.isHovered = value
    })
  }
}
