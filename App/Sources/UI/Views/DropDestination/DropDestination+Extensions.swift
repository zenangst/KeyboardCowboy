import Foundation

extension RandomAccessCollection where Element: Identifiable, Index == Int {
  func deleteOffsets(for ids: Set<Element.ID>) -> [Int] {
    enumerated()
      .filter { ids.contains($0.element.id) }
      .map(\.offset)
  }

  func moveOffsets(for element: Element, with ids: [Element.ID]) -> (fromOffsets: IndexSet, toOffset: Int)? {
    guard var toOffset = firstIndex(where: { $0.id == element.id }) else { return nil }

    let fromOffsets = IndexSet(enumerated()
      .filter { ids.contains($0.element.id) }
      .map(\.offset))

    if toOffset >= fromOffsets.max() ?? 0 {
      toOffset += 1
    }

    return (fromOffsets: IndexSet(fromOffsets), toOffset: toOffset)
  }
}
