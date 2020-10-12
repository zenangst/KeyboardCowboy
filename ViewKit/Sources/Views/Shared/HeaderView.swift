import SwiftUI

struct HeaderView: View {
  let title: String

  var body: some View {
    Text(title)
      .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
      .font(.subheadline)
      .foregroundColor(Color.secondary)
  }
}
