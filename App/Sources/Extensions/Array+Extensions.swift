import Foundation

extension Array where Element: Equatable {
  func contains(_ element: Element?) -> Bool {
    guard let element = element else {
      return false
    }

    return contains { $0 == element }
  }
}
