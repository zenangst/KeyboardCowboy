import SwiftUI

struct HeaderLabelStyle: LabelStyle {
  @ObservedObject private var iO = Inject.observer
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
