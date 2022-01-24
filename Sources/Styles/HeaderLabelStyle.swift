import SwiftUI

struct HeaderLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.title
      .font(.subheadline)
      .foregroundColor(Color.secondary)
  }
}
