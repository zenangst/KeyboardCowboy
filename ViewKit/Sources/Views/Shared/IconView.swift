import SwiftUI

struct Icon: Hashable, Identifiable {
  let identifier: String
  let path: String
  let id: String

  init(identifier: String, path: String) {
    self.identifier = identifier
    self.path = path
    self.id = identifier + path
  }
}

struct IconView: View {
  @ObservedObject var iconLoader = IconController()

  let icon: Icon

  init(icon: Icon) {
    self.icon = icon
    iconLoader.preLoadIcon(identifier: icon.identifier, at: icon.path, size: CGSize(width: 24, height: 24))
  }

  var body: some View {
    ZStack {
      if iconLoader.icon != nil {
        Image(nsImage: iconLoader.icon!)
      }
    }.onAppear {
      if iconLoader.icon == nil {
        iconLoader.loadIcon(identifier: icon.identifier, at: icon.path, size: CGSize(width: 24, height: 24))
      }
    }
    .frame(width: 24, height: 24)
  }
}

struct IconView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    Group {
      IconView(icon: Icon(identifier: "com.apple.Finder",
                          path: "/System/Library/CoreServices/Finder.app"))
      IconView(icon: Icon(identifier: "keyboard",
                          path: "/System/Library/PreferencePanes/Keyboard.prefPane"))
    }.frame(width: 48, height: 48)
  }
}
