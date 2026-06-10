import SwiftUI

extension DetailSplit {
  struct EnableButton: View {
    var body: some View {
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
