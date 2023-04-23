import Foundation

final class MoveManager<T: Identifiable> {
  func onDropDestination(_ items: [T],
                         index: Int,
                         data: [T],
                         selections: Set<T.ID>) -> IndexSet {
    if !Set(items.map(\.id)).intersection(selections).isEmpty {
      let source = IndexSet(data.enumerated().compactMap { (index, model) -> Int? in
        selections.contains(model.id) ? index : nil
      })
      return source
    } else {
      let ids = items.map(\.id)
      let source = IndexSet(data.enumerated().compactMap { (index, model) -> Int? in
        ids.contains(model.id) ? index : nil
      })
      return source
    }
  }
}
