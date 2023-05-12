import Foundation

extension String {
  func draggablePayload(prefix: String) -> [String] {
    var copy = self
    if copy.hasPrefix(prefix) {
      copy.removeFirst(prefix.count)
      return copy.split(separator: ",").map(String.init)
    } else {
      return []
    }
  }
}

extension Collection where Element == String {
  func draggablePayload(prefix: String) -> [String] {
    first?.draggablePayload(prefix: prefix) ?? []
  }
}

extension RandomAccessCollection where Element: Identifiable, Index == Int {
  func deleteOffsets(for ids: Set<Element.ID>) -> Array<Int> {
    enumerated()
      .filter { ids.contains($0.element.id) }
      .map { $0.offset }
  }

  func moveOffsets(for element: Element, with ids: [Element.ID]) -> (fromOffsets: IndexSet, toOffset: Int)? {
    guard var toOffset = firstIndex(where: { $0.id == element.id }) else { return nil }

    let fromOffsets = IndexSet(enumerated()
      .filter { ids.contains($0.element.id) }
      .map { $0.offset })

    if toOffset >= fromOffsets.max() ?? 0 {
      toOffset += 1
    }

    return (fromOffsets: IndexSet(fromOffsets), toOffset: toOffset)
  }
}
