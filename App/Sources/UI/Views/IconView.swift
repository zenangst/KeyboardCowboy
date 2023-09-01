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
  private var passthrough = PassthroughSubject<CGSize, Never>()
  private var subscription: AnyCancellable?

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
    self.subscription = passthrough
      .sink { [weak self] size in
        guard let self else { return }
        self.internalLoad(size)
      }
  }

  deinit {
    task?.cancel()
  }

  func load(with size: CGSize) async {
    task?.cancel()
    passthrough.send(size)
  }

  private func internalLoad(_ size: CGSize) {
    self.task?.cancel()
    let path = path
    let task = Task {
      guard let data = await IconCache.shared.icon(at: path, bundleIdentifier: path, size: size),
            let nsImage = NSImage(data: data)
      else { return }

      let image = Image(nsImage: nsImage)
      try Task.checkCancellation()
      try await MainActor.run {
        try Task.checkCancellation()
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
