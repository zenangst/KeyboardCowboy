import ScriptingBridge

final class SBFinder {
  @MainActor
  static func getSelections(_ firstUrl: inout String?,
                            selections: inout [String]) {
    guard let application: SBFinderApp = SBApplication(bundleIdentifier: "com.apple.finder") else { return }
    if let items = application.selection?.get() as? [SBObject] {
      if items.isEmpty, let windows = application.windows?.get() as? [SBObject] {
        // Check for location of the first open Finder window
        for ref in windows {
          let url = (ref as SBFinderWindow).target?.URL
          firstUrl = url
          break
        }
      } else {
        // There is at least one item in the selection
        for ref in items {
          let item = ref as SBFinderFile
          if let urlString = item.URL {
            if firstUrl == nil { firstUrl = urlString }
            selections.append(urlString)
          }
        }
      }
    }
  }
}

@objc fileprivate protocol SBFinderApp {
  @objc optional var selection: SBElementArray { get }
  @objc optional var windows: SBElementArray { get }
}

@objc fileprivate protocol SBFinderWindow {
  @objc optional var target: SBFinderFile { get }
  @objc optional var name: String { get }
  @objc optional var index: Int { get }
}

@objc fileprivate protocol SBFinderFile {
  @objc optional var name: String { get }
  @objc optional var URL: String { get }
}

extension SBApplication: SBFinderApp {}
extension SBObject: SBFinderFile {}
extension SBObject: SBFinderWindow {}
