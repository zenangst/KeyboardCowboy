import SwiftUI

struct SidebarLabelStyle: LabelStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.title
      .font(.subheadline.bold())
      .allowsTightening(true)
      .lineLimit(1)
      .foregroundColor(Color.secondary)
      .frame(height: 12)
    }
}

extension Text {
  @ViewBuilder
  func sidebarLabel() -> some View {
    self
      .font(.subheadline.bold())
      .allowsTightening(true)
      .lineLimit(1)
      .foregroundColor(Color.secondary)
      .frame(height: 12)
  }
}
