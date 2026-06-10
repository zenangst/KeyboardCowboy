import SwiftUI

struct SymbolImage: View {
  let systemName: String

  init(_ systemName: String) {
    self.systemName = systemName
  }

  var body: some View {
    Image(systemName: systemName)
      .resizable()
      .aspectRatio(contentMode: .fit)
  }
}
