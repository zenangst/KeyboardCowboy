import SwiftUI

@Injectable
struct SymbolImage: View {
  let systemName: String

  init(_ systemName: String) {
    self.systemName = systemName
  }

  var content: some View {
    Image(systemName: systemName)
      .resizable()
      .scaledToFit()
  }
}
