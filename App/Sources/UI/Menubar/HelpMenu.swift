import SwiftUI

struct HelpMenu: View {
  enum Action {
    case releaseNotes, wiki, discussions, fileBug
  }

  private let onAction: (Action) -> Void

  init(onAction: @escaping (Action) -> Void) {
    self.onAction = onAction
  }

  var body: some View {
    Button { onAction(.releaseNotes) } label: { Text("What's New?") }
    Button(action: { onAction(.wiki) }, label: { Text("Wiki") })
    Button(action: { onAction(.discussions) }, label: { Text("Discussions") })
    Button(action: { onAction(.fileBug) }, label: { Text("File a Bug") })
  }
}
