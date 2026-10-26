import SwiftUI

extension SidebarSplit {
  @Injectable
  struct UserModes: View {

    var content: some View {
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
    }
  }
}
