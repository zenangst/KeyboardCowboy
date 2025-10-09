import SwiftUI

struct DetailEmptyView: View {
  var body: some View {
    Text("No workflow selected")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct DetailEmptyView_Previews: PreviewProvider {
  static var previews: some View {
    DetailEmptyView()
  }
}
