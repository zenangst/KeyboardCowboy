import SwiftUI

struct IconView: View {
  let icon: IconViewModel
  let size: CGSize

  var body: some View {
    InternalIconView(at: icon.path, size: size, content: { phase in
      Group {
        switch phase {
        case .success(let image):
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
            .fixedSize()
        case .empty, .failure:
          placeholder()
        @unknown default:
          placeholder()
        }
      }
    })
  }

  private func placeholder() -> some View {
    Rectangle()
      .fill(.clear)
      .frame(width: size.width, height: size.height)
      .fixedSize()
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
  private var task: Task<(), Never>? {
    willSet {
      self.task?.cancel()
    }
  }
  private let path: String

  init(at path: String) {
    self.path = path
  }

  func load(with size: CGSize) async {
    self.task?.cancel()
    let path = path
    let task = Task {
      guard let cgImage = await IconCache.shared.icon(at: path, bundleIdentifier: path, size: size) else {
        return
      }
      let image = Image(cgImage, scale: 1.0, label: Text(""))
      await MainActor.run {
        phase = .success(image)
      }
    }
    self.task = task
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
