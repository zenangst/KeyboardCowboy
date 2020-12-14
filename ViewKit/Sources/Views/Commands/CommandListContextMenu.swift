import SwiftUI
import ModelKit

struct CommandListContextMenu: View {
  let editAction: () -> Void
  let deleteAction: () -> Void

  var body: some View {
    Button("Show Info", action: editAction)
    Divider()
    Button("Delete", action: deleteAction)
  }
}
