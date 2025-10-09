import Foundation

extension KeyboardCowboyConfiguration {
  @discardableResult mutating func update<Value>(
    groupID: WorkflowGroup.ID,
    keyPath: WritableKeyPath<WorkflowGroup, Value>,
    newValue: Value,
  ) -> Bool {
    guard let groupIndex = resolveIndex(groupID: groupID) else { return false }

    groups[groupIndex][keyPath: keyPath] = newValue
    return true
  }

  @discardableResult mutating func modify(
    groupID: WorkflowGroup.ID,
    modify: (inout WorkflowGroup) -> Void,
  ) -> Bool {
    guard let groupIndex = resolveIndex(groupID: groupID) else { return false }

    var group = groups[groupIndex]
    let oldGroup = group
    modify(&group)

    guard group != oldGroup else { return false }

    groups[groupIndex] = group
    return true
  }

  @discardableResult mutating func replace(
    groupID: WorkflowGroup.ID,
    group newGroup: WorkflowGroup,
  ) -> Bool {
    guard let groupIndex = resolveIndex(groupID: groupID) else { return false }

    groups[groupIndex] = newGroup
    return true
  }

  @discardableResult mutating func insert(group newGroup: WorkflowGroup, at index: Int) -> Bool {
    if groups.isEmpty {
      groups.append(newGroup)
    } else {
      let safeIndex = max(min(index, groups.count), 0)
      groups.insert(newGroup, at: safeIndex)
    }
    return true
  }
}
