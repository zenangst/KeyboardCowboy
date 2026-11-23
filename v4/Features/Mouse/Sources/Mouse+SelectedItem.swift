extension Mouse {
  static func selectedItem<Node>(
    in branches: [Node], collection: Bool,
    children: (Node) throws -> [Node],
    focused: (Node) throws -> Bool,
    selected: (Node) throws -> Bool,
    checkpoint: () throws -> Void,
  ) throws -> Node? {
    func firstSelected(in nodes: [Node]) throws -> Node? {
      try nodes.first { node in
        try checkpoint()
        return try bestEffort { try selected(node) } == true
      }
    }

    var match: Node?
    for branch in branches {
      try checkpoint()
      let items = try bestEffort { try children(branch) } ?? []
      if collection {
        for group in items {
          try checkpoint()
          let members = try bestEffort { try children(group) } ?? []
          if let first = try firstSelected(in: members) { match = first }
        }
      } else if !items.isEmpty {
        if let first = try firstSelected(in: items) { match = first }
      } else if try bestEffort({ try focused(branch) }) == true {
        return branch
      }
    }
    return match
  }

  private static func bestEffort<Value>(_ read: () throws -> Value) throws -> Value? {
    do {
      return try read()
    } catch let cancelled as CancellationError {
      throw cancelled
    } catch {
      return nil
    }
  }
}
