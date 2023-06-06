import SwiftUI

@MainActor
final class IconPublisher: ObservableObject {
  @Published var cgImage: CGImage?

  func load(at path: String, bundleIdentifier: String, of size: CGSize) {
    Task {
      cgImage = await IconCache.shared.icon(at: path, bundleIdentifier: bundleIdentifier, size: size)
    }
  }
}

struct IconView: View {
  @StateObject var publisher = IconPublisher()

  let icon: IconViewModel
  let size: CGSize

  var body: some View {
    Group {
      if let cgImage = publisher.cgImage {
        Image(nsImage: NSImage(cgImage: cgImage, size: size))
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size.width, height: size.height)
          .fixedSize()
      } else {
        Rectangle()
          .fill(.clear)
          .frame(width: size.width, height: size.height)
          .fixedSize()
      }
    }
    .animation(.easeInOut(duration: 1.0), value: publisher.cgImage)
    .onAppear {
      publisher.load(at: icon.path, bundleIdentifier: icon.bundleIdentifier, of: size)
    }
    .id(icon.id)
  }
}

struct IconView_Previews: PreviewProvider {
  static var previews: some View {
    IconView(icon: .init(bundleIdentifier: "com.apple.finder.",
                         path: "/System/Library/CoreServices/Finder.app"),
             size: .init(width: 32, height: 32))
  }
}
