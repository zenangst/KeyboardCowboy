import SwiftUI

struct IconView: View {
  let path: String
  @StateObject var iconLoader = IconLoader()

  var body: some View {
    ZStack {
      iconLoader.image
    }
    .onAppear { iconLoader.load(path) }
    .onDisappear { iconLoader.cancel() }
  }
}

struct IconView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      IconView(path: "/System/Library/CoreServices/Finder.app")
      IconView(path: "/System/Library/PreferencePanes/Keyboard.prefPane")
    }.frame(width: 48, height: 48)
  }
}
