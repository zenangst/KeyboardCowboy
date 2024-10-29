import Bonzai
import SwiftUI

struct CompatList<Content>: View where Content: View {
  let content: () -> Content

  init(@ViewBuilder _ content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    if #available(macOS 15.0, *) {
      ZenList {
        content()
      }
    } else {
      ScrollView {
        LazyVStack(spacing: 0) {
          content()
        }
      }
    }
  }
}
