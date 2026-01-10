import ScriptingBridge

enum SBFinder {
  @MainActor
  static func getSelections(_ firstUrl: inout String?,
                            selections: inout [String]) {
    guard let application: SBApp = SBApplication(bundleIdentifier: "com.apple.finder") else { return }

    if let items = application.selection?.get() as? [SBObject] {
      if items.isEmpty, let windows = application.windows?.get() as? [SBObject] {
        // Check for location of the first open Finder window

        for ref in windows {
          let url = (ref as SBWindow).target?.URL
          firstUrl = url
          break
        }
      } else {
        // There is at least one item in the selection
        for ref in items {
          let item = ref as SBFile
          if let urlString = item.URL {
            if firstUrl == nil { firstUrl = urlString }
            selections.append(urlString)
          }
        }
      }
    }
  }
}

@objc private protocol SBApp {
  @objc optional var selection: SBElementArray { get }
  @objc optional var windows: SBElementArray { get }
}

@objc private protocol SBWindow {
  @objc optional var target: SBFile { get }
  @objc optional var name: String { get }
  @objc optional var index: Int { get }
}

@objc private protocol SBFile {
  @objc optional var name: String { get }
  @objc optional var URL: String { get }
}

extension SBApplication: SBApp {}
extension SBObject: SBFile {}
extension SBObject: SBWindow {}
