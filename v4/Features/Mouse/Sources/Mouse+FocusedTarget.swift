import AccessibilitySystem
import CoreGraphics

public enum Mouse {
  public enum Anchor: Codable, Hashable, Sendable {
    case topLeading, top, topTrailing
    case leading, center, trailing
    case bottomLeading, bottom, bottomTrailing
    case custom(x: Int, y: Int)

    /// Uses AX global screen coordinates. Custom coordinates are absolute.
    public func point(in frame: CGRect) -> CGPoint {
      let point: CGPoint = switch self {
      case .topLeading: CGPoint(x: frame.minX, y: frame.minY)
      case .top: CGPoint(x: frame.midX, y: frame.minY)
      case .topTrailing: CGPoint(x: frame.maxX, y: frame.minY)
      case .leading: CGPoint(x: frame.minX, y: frame.midY)
      case .center: CGPoint(x: frame.midX, y: frame.midY)
      case .trailing: CGPoint(x: frame.maxX, y: frame.midY)
      case .bottomLeading: CGPoint(x: frame.minX, y: frame.maxY)
      case .bottom: CGPoint(x: frame.midX, y: frame.maxY)
      case .bottomTrailing: CGPoint(x: frame.maxX, y: frame.maxY)
      case .custom(let x, let y): CGPoint(x: x, y: y)
      }
      return CGPoint(x: point.x + 5, y: point.y + 5)
    }
  }

  public enum TargetError: Error {
    case noSelectedChild
  }

  /// Resolves direct-frame roles, groups, tables, outlines, lists, collections,
  /// scroll areas, and web areas. Unsupported roles return nil.
  public static func focusedTarget(
    at anchor: Anchor,
    selectedText: String = "",
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> CGPoint? {
    try await accessibility.withFocusedElement { element -> CGPoint? in
      guard let kind = try targetKind(role: element.read(.role), legacyDescription: { try element.read(.roleDescription) })
      else { return nil }
      if kind == .group, let child = try element.firstChild(where: { child in
        isGroupTarget(focused: { try child.read(.focused) },
                      selected: { try child.read(.selected) })
      }) {
        return try anchor.point(in: CGRect(origin: child.read(.position),
                                           size: child.read(.size)))
      }
      return try target(
        kind: kind,
        at: anchor, selectedFrame: {
          let child: AccessibilitySystem.FocusedElement.Child?
          if kind == .list || kind == .collection {
            child = try selectedItem(
              in: element.children(), collection: kind == .collection,
              children: { try $0.children() }, focused: { try $0.read(.focused) },
              selected: { try $0.read(.selected) }, checkpoint: element.checkpoint)
          } else if kind == .scrollArea {
            child = try element.firstInSubtreeWithReadableChildren { node in
              isGroupTarget(focused: { try node.read(.focused) }, selected: { try node.read(.selected) })
            }
          } else if kind == .webArea {
            var selection = HTMLSelection(selectedText)
            child = try element.firstLeaf { leaf in
              selection.matchesLeaf(
                text: { try? leaf.read(.textValue) },
                isFocusedOrSelected: {
                  isGroupTarget(focused: { try leaf.read(.focused) }, selected: { try leaf.read(.selected) })
                })
            }
          } else {
            child = try element.firstChild { (try? $0.read(.selected)) == true }
          }
          return try child.map { try CGRect(origin: $0.read(.position), size: $0.read(.size)) }
        }, frame: {
          try CGRect(origin: element.read(.position), size: element.read(.size))
        })
    }
  }

  enum TargetKind {
    case group, frame, selectedChild, list, collection, scrollArea, webArea
  }

  static func targetKind(
    role: AccessibilitySystem.Role, legacyDescription: () throws -> String,
  ) rethrows -> TargetKind? {
    switch role {
    case .group: return .group
    case .image, .textField: return .frame
    case .table, .outline: return .selectedChild
    case .list: return .list
    case .scrollArea: return .scrollArea
    case .webArea: return .webArea
    default: break
    }

    // Keep the legacy distinctions until these targets have verified role/subrole mappings.
    switch try legacyDescription() {
    case "outline row", "text": return .frame
    case "collection": return .collection
    case "HTML content": return .webArea
    default: return nil
    }
  }

  static func target(
    kind: TargetKind, at anchor: Anchor,
    selectedFrame: () throws -> CGRect?, frame: () throws -> CGRect,
  ) throws -> CGPoint {
    switch kind {
    case .group, .frame:
      return try anchor.point(in: frame())
    case .selectedChild, .list, .collection, .scrollArea, .webArea:
      guard let frame = try selectedFrame() else { throw TargetError.noSelectedChild }

      return anchor.point(in: frame)
    }
  }

  static func isGroupTarget(focused: () throws -> Bool, selected: () throws -> Bool) -> Bool {
    (try? focused()) == true || (try? selected()) == true
  }
}
