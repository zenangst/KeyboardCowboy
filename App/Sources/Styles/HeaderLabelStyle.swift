import SwiftUI

struct HeaderLabelStyle: LabelStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.title
      .font(.system(.body, design: .rounded,weight: .semibold))
      .allowsTightening(true)
      .lineLimit(1)
      .foregroundColor(Color.secondary)
      .frame(height: 12)
    }
}
