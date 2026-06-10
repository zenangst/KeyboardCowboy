import HotSwiftUI
import SwiftUI

struct ButtonsScreen: View {
  @ObserveInjection private var inject

  var body: some View {
    VStack {
      Button(action: {}, label: {
        Text("Hello")
      })
      Button(action: {}, label: {
        Text("World")
      })
    }
    .enableInjection()
  }
}
