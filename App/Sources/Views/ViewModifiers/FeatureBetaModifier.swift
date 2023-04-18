import SwiftUI

struct FeatureBetaModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .overlay(
        Text("Beta")
      )
  }
}

struct FeatureDebugModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("This is a text")
        .modifier(FeatureBetaModifier())
    }
}
