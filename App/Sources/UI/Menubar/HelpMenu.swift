import SwiftUI

struct HelpMenu: View {
  var body: some View {
    Button(action: {
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/wiki")!)
    }, label: {
      Text("Wiki")
    })

    Button(action: {
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/discussions")!)
    }, label: {
      Text("Discussions")
    })

    Button(action: {
      NSWorkspace.shared.open(URL(string: "https://github.com/zenangst/KeyboardCowboy/issues/new")!)
    }, label: {
      Text("File a Bug")
    })
  }
}
