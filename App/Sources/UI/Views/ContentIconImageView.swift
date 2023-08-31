import SwiftUI

struct ContentIconImageView: View {
  let icon: IconViewModel
  let size: CGFloat

  var body: some View {
    IconView(icon: icon, size: .init(width: size, height: size))
      .fixedSize()
      .id(icon)
  }
}

struct ContentIconImageView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ContentIconImageView(
        icon: .init(
          bundleIdentifier: "com.apple.finder",
          path: "/System/Library/CoreServices/Finder.app"
        ),
        size: 32
      )
    }
    .frame(minWidth: 200, minHeight: 120)
    .padding()
  }
}
