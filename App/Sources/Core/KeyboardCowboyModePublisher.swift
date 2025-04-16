import Combine
import Foundation

final class KeyboardCowboyModePublisher: ObservableObject {
  @Published var isEnabled: Bool = true

  private var subscription: AnyCancellable?

  init(source publisher: Published<KeyboardCowboyMode>.Publisher) {
    subscribe(to: publisher)
  }

  func subscribe(to publisher: Published<KeyboardCowboyMode>.Publisher) {
    subscription = publisher.sink { [weak self] mode in
      self?.isEnabled = mode != .disabled
    }
  }
}
