import HotSwiftUI
import SwiftUI

extension SidebarSplit {
  struct UserModes: View {
    @ObserveInjection private var inject

    var body: some View {
      VStack {
        HStack {
          Label("User Modes")
          Spacer()
          Button(action: {}, label: {
            SymbolImage("plus.circle")
              .frame(width: 12, height: 12)
          })
          .buttonStyle(.accessoryBar)
        }
      }
      .enableInjection()
    }
  }
}
