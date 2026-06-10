import HotSwiftUI
import SwiftUI

struct ButtonsScreen: View {
  @ObserveInjection private var inject

  var body: some View {
    HStack {
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
