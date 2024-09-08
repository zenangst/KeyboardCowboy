import SwiftUI

struct IconPreview<Content>: View where Content: View {
  let content: (CGFloat) -> Content

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      content(192)
      VStack(alignment: .leading, spacing: 8) {
        content(128)
        HStack(alignment: .top, spacing: 8) {
          content(64)
          content(32)
          content(16)
        }
      }
    }
    .padding()
  }
}
