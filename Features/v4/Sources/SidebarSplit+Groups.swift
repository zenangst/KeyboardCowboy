import SwiftUI

extension SidebarSplit {
  @Injectable
  struct Groups: View {

    var content: some View {
      VStack {
        Label("Groups")

        Button(action: {}, label: {
          Text("I'm a sidebar")
            .frame(maxWidth: .infinity, alignment: .leading)
        })
      }
    }
  }
}
