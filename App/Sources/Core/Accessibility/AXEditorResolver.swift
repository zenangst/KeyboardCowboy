import AppKit
import AXEssibility
import Foundation

enum AXEditorResolverError: Error {
  case noResult
}

enum AXEditorResolver {
  static func resolveFocusedElement(_ parent: AnyFocusedAccessibilityElement) throws -> CGRect {
    var frame: CGRect?
    if var textRange = try? parent.value(.selectedTextRange, as: CFRange.self),
       let axValue = AXValueCreate(.cfRange, &textRange),
       let rect = try? parent.reference.parameterizedValue(
         key: kAXBoundsForRangeParameterizedAttribute,
         parameters: axValue,
         as: AXValue.self,
       ) {
      let defaultFrame = CGRect(x: -1, y: -1, width: -1, height: -1)
      var resolvedFrame: CGRect = defaultFrame
      _ = AXValueGetValue(rect, .cgRect, &resolvedFrame)
      if resolvedFrame != defaultFrame {
        frame = resolvedFrame
      }
    }

    guard let frame else {
      throw AXTextEntryAreaResolverError.noResult
    }

    return frame
  }
}
