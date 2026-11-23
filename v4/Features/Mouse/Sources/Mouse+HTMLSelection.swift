extension Mouse {
  struct HTMLSelection {
    private let selection: String
    private var textSoFar = ""

    init(_ selection: String) {
      self.selection = selection.lowercased()
    }

    mutating func matchesLeaf(text: () -> String?, isFocusedOrSelected: () -> Bool) -> Bool {
      guard !selection.isEmpty else { return isFocusedOrSelected() }
      if let text = text() { textSoFar += text }
      return textSoFar.lowercased().contains(selection)
    }
  }
}
