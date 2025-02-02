import Foundation

extension Array: @retroactive RawRepresentable where Element: Codable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode([Element].self, from: data)
    else {
      return nil
    }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

extension Array where Element: Identifiable {
  mutating func replace(_ element: Element) {
    if let index = firstIndex(where: { $0.id == element.id }) {
      self[index] = element
    }
  }

  mutating func remove(_ element: Element) {
    if let index = firstIndex(where: { $0.id == element.id }) {
      remove(at: index)
    }
  }
}


public extension Array {
  func asyncMap<T>(_ transform: @Sendable (Element) async -> T) async -> [T] where T: Sendable {
    var newArray = [T]()
    newArray.reserveCapacity(count)
    var index = 0
    while index < self.count {
      let newItem = await transform(self[index])
      newArray.append(newItem)
      index += 1
    }
    return newArray
  }

  func asyncCompactMap<T>(_ transform: @Sendable (Element) async -> T?) async -> [T] where T: Sendable {
    var newArray = [T]()
    newArray.reserveCapacity(count)
    var index = 0
    while index < self.count {
      if let newItem = await transform(self[index]) {
        newArray.append(newItem)
      }
      index += 1
    }
    return newArray
  }
}
