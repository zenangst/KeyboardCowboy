import Foundation

public final class RingBuffer<T: Identifiable & Hashable> {
  public private(set) var cursor: Int
  public private(set) var currentEntries: [T] = []

  public init(cursor: Int = 0) {
    self.cursor = cursor
  }

  public func update(_ newEntries: [T]) {
    if currentEntries.isEmpty {
      currentEntries = newEntries
      cursor = min(cursor, max(newEntries.count - 1, 0))
      return
    }
    if newEntries.isEmpty {
      currentEntries.removeAll()
      cursor = 0
      return
    }

    let newByID = Dictionary(uniqueKeysWithValues: newEntries.map { ($0.id, $0) })
    let currentByID = Dictionary(uniqueKeysWithValues: currentEntries.map { ($0.id, $0) })

    let newIDs = Set(newByID.keys)
    let currentIDs = Set(currentByID.keys)

    let addedIDs = newIDs.subtracting(currentIDs)
    let removedIDs = currentIDs.subtracting(newIDs)
    let commonIDs = newIDs.intersection(currentIDs)

    var updated = currentEntries.filter { !removedIDs.contains($0.id) }

    if !commonIDs.isEmpty {
      updated = updated.map { old in
        if let fresh = newByID[old.id] {
          return fresh // "new wins"
        } else {
          return old
        }
      }
    }

    if !addedIDs.isEmpty {
      if updated[safe: cursor] != nil {
        let insertIndex = min(cursor + 1, updated.count)
        for id in addedIDs {
          if let entry = newByID[id] {
            updated.insert(entry, at: min(insertIndex, updated.count))
          }
        }
      } else {
        for id in addedIDs {
          if let entry = newByID[id] {
            updated.append(entry)
          }
        }
      }
    }

    currentEntries = updated

    if let currentEntry = currentEntries[safe: cursor],
       let newIndex = currentEntries.firstIndex(where: { $0.id == currentEntry.id })
    {
      cursor = newIndex
    } else {
      cursor = 0
    }
  }

  public func setCursor(to entry: T) {
    if let match = currentEntries.firstIndex(of: entry) {
      cursor = match
    }
  }

  public func moveEntryToCursor(_ entry: T) {
    currentEntries.removeAll { $0.id == entry.id }
    currentEntries.insert(entry, at: max(cursor, currentEntries.count - 1))
  }

  public func navigate(_ direction: RingBufferDirection, entries: [T]) -> T? {
    update(entries)

    guard currentEntries.isEmpty == false else {
      return nil
    }

    cursor = switch direction {
    case .left: (cursor - 1 + entries.count) % entries.count
    case .right: (cursor + 1) % entries.count
    }

    return currentEntries[cursor]
  }
}

public extension Collection {
  subscript(safe index: Self.Index) -> Element? {
    guard indices.contains(index) else {
      return nil
    }

    return self[index]
  }
}

public enum RingBufferDirection {
  case left, right
}
