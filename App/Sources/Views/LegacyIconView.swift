import SwiftUI

struct LegacyIconView: View {
  let path: String
  @StateObject var store = IconStore()

  var body: some View {
    ZStack {
      store.image?
        .resizable()
    }
    .frame(minWidth: 12, minHeight: 12)
    .onAppear { store.load(path) }
    .onDisappear { store.cancel() }
  }
}

struct LegacyIconView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      LegacyIconView(path: "/System/Library/CoreServices/Finder.app")
      LegacyIconView(path: "/System/Library/PreferencePanes/Keyboard.prefPane")
    }.frame(width: 48, height: 48)
  }
}
