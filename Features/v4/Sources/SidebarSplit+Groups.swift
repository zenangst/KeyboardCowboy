import HotSwiftUI
import SwiftUI

extension SidebarSplit {
  struct Groups: View {
    @ObserveInjection private var inject

    var body: some View {
      VStack {
        Label("Groups")

        Button(action: {}, label: {
          Text("I'm a sidebar")
            .frame(maxWidth: .infinity, alignment: .leading)
        })
      }
      .enableInjection()
    }
  }
}
