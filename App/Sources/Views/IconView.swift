import SwiftUI

final class IconPublisher: ObservableObject {
  @Published var image: NSImage?

  func load(at path: String, bundleIdentifier: String, of size: CGSize) {
    if let cachedImage = IconCache.shared.loadFromCache(at: path, bundleIdentifier: bundleIdentifier, size: size) {
      image = cachedImage
    } else {
      Task {
        let image = await IconCache.shared.icon(
          at: path,
          bundleIdentifier: bundleIdentifier,
          size: size)
        await MainActor.run { self.image = image }
      }
    }
  }
}

struct IconView: View {
  @StateObject var publisher = IconPublisher()

  let icon: IconViewModel
  let size: CGSize

  var body: some View {
    Group {
      if let image = publisher.image {
        Image(nsImage: image)
          .resizable()
      } else {
        Rectangle()
          .fill(.clear)
      }
    }
    .aspectRatio(contentMode: .fit)
    .frame(width: size.width, height: size.height)
    .onAppear {
      publisher.load(at: icon.path, bundleIdentifier: icon.bundleIdentifier, of: size)
    }
  }
}

struct IconView_Previews: PreviewProvider {
  static var previews: some View {
    IconView(icon: .init(bundleIdentifier: "com.apple.finder.",
                         path: "/System/Library/CoreServices/Finder.app"),
             size: .init(width: 32, height: 32))
  }
}
