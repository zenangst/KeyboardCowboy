import Combine
import SwiftUI

struct IconView: View {
  let icon: IconViewModel
  let size: CGSize
  @State var visible: Bool = false

  var body: some View {
    InternalIconView(at: icon.path, size: size, content: { phase in
      if case .success(let image) = phase {
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: size.width, height: size.height)
          .fixedSize()
      } else {
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.clear)
          .frame(width: size.width, height: size.height)
          .fixedSize()
      }
    })
    .drawingGroup()
  }
}

struct IconView_Previews: PreviewProvider {
  static var previews: some View {
    IconView(icon: .init(bundleIdentifier: "com.apple.finder.",
                         path: "/System/Library/CoreServices/Finder.app"),
             size: .init(width: 32, height: 32))
  }
}

fileprivate final class ImageLoader: ObservableObject {
  @MainActor
  @Published var phase = AsyncImagePhase.empty

  private var task: Task<(), Error>? {
    willSet {
      self.task?.cancel()
    }
  }
  private let path: String

  init(at path: String) {
    self.path = path
  }

  deinit {
    task?.cancel()
  }

  @MainActor
  func load(with size: CGSize) async {
    if let data = await IconCache.shared.iconFromCache(at: path, bundleIdentifier: path, size: size),
       let nsImage = NSImage(data: data) {
      nsImage.size = size
      phase = .success(Image(nsImage: nsImage))
    } else {
      await internalLoad(size)
    }
  }

  private func internalLoad(_ size: CGSize) async {
    self.task?.cancel()
    let path = path
    guard let data = await IconCache.shared.icon(at: path, bundleIdentifier: path, size: size),
          let nsImage = NSImage(data: data)
    else { return }

    let image = Image(nsImage: nsImage)
    await MainActor.run {
      phase = .success(image)
    }
  }
}

fileprivate struct InternalIconView<Content>: View where Content: View {
  @StateObject fileprivate var loader: ImageLoader
  @ViewBuilder private var content: (AsyncImagePhase) -> Content
  private let size: CGSize

  init(at path: String,
       size: CGSize,
       @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
    _loader = .init(wrappedValue: ImageLoader(at: path))
    self.size = size
    self.content = content
  }

  var body: some View {
    content(loader.phase)
      .task {
        await loader.load(with: size)
      }
  }
}
