import SwiftUI

extension ContentSplit {
  @Injectable
  struct AddWorkflow: View {

    let action: () -> Void

    var content: some View {
      Button(action: action, label: {
        SwiftUI.Label(title: { Text("Add Group") }, icon: {
          Image(systemName: "plus")
        })
      })
      .labelStyle(.iconOnly)
    }
  }
}
