import SwiftUI

struct IconView: View {
  @ObservedObject var iconLoader = IconController()

  let identifier: String
  let path: String

  var body: some View {
    ZStack {
      if iconLoader.icon != nil {
        Image(nsImage: iconLoader.icon!)
          .resizable()
      } else {
        EmptyView()
      }
    }.onAppear {
      iconLoader.loadIcon(identifier: identifier, at: path)
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
