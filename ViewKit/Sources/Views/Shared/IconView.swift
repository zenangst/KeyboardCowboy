import SwiftUI

struct IconView: View {
  @ObservedObject var iconLoader = IconController()

  init(identifier: String, path: String) {
    iconLoader.load(identifier: identifier, at: path)
  }

  var body: some View {
    if iconLoader.icon != nil {
      Image(nsImage: iconLoader.icon!)
        .resizable()
    } else {
      EmptyView()
    }
  }
}

struct IconView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      IconView(identifier: "com.apple.Finder", path: "/System/Library/CoreServices/Finder.app")
      IconView(identifier: "keyboard", path: "/System/Library/PreferencePanes/Keyboard.prefPane")
    }.frame(width: 48, height: 48)
  }
}
