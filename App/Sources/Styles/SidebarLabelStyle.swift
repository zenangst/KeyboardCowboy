import SwiftUI

struct SidebarLabelStyle: LabelStyle {
  @ObserveInjection var inject
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.title
      .font(.subheadline.bold())
      .allowsTightening(true)
      .lineLimit(1)
      .foregroundColor(Color.secondary)
      .frame(height: 12)
      .enableInjection()
  }
}
