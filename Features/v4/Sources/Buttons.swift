import SwiftUI

@Injectable
struct ButtonsScreen: View {
  var content: some View {
    HStack {
      Button(action: {}, label: {
        Text("Hello")
      })
      Button(action: {}, label: {
        Text("World")
      })
      Button(action: {}, label: {
        Text("!")
      })
    }
  }
}
