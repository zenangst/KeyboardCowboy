import Cocoa
import Combine

final class ShortcutStore: ObservableObject, @unchecked Sendable {
  @MainActor
  @Published private(set) var shortcuts = [Shortcut]()
  private var subscription: AnyCancellable?

  static let shared: ShortcutStore = .init()

  private init() { }

  func subscribe(to application: Published<UserSpace.Application>.Publisher) {
    subscription = application
      .filter { $0.bundleIdentifier == "com.apple.shortcuts" }
      .sink { [weak self] application in
        guard let self else { return }
        Task {
          await self.index()
        }
      }
  }

  func index() async {
    guard let newShortcuts = try? SBShortcuts.getShortcuts() else { return }
    await MainActor.run {
      self.shortcuts = newShortcuts
    }
  }
}
