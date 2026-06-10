import HotSwiftUI
import SwiftUI

extension ContentSplit {
  struct AddWorkflow: View {
    @ObserveInjection private var inject

    let action: () -> Void

    var body: some View {
      Button(action: action, label: {
        SwiftUI.Label(title: { Text("Add Group") }, icon: {
          Image(systemName: "plus")
        })
      })
      .labelStyle(.iconOnly)
      .enableInjection()
    }
  }
}
