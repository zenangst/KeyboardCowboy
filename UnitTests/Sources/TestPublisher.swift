import Foundation

class TestPublisher<T> {
  @Published var current: T

  init(current: T) {
    self.current = current
  }
}
