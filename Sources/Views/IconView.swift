import SwiftUI

struct IconView: View {
  @ObservedObject private var iO = Inject.observer
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
    .enableInjection()
  }
}

struct IconView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      IconView(path: "/System/Library/CoreServices/Finder.app")
      IconView(path: "/System/Library/PreferencePanes/Keyboard.prefPane")
    }.frame(width: 48, height: 48)
  }
}
