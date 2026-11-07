import SwiftUI

extension DetailSplit {
  @Injectable
  struct EnableButton: View {
    var content: some View {
      Button(action: {}, label: {
        SymbolImage("power.circle.fill")
          .padding(.leading)
        Text("Enabled")
          .padding(.trailing)
      })
      .foregroundStyle(Color(nsColor: .systemGreen))
    }
  }
}
