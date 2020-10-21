import Cocoa
import Foundation
import ModelKit

class ApplicationParser {
  func process(_ url: URL) -> Application? {
    guard let bundle = Bundle(url: url),
          let bundleIdentifier = bundle.bundleIdentifier,
          let infoDictionary = bundle.infoDictionary else {
      return nil
    }

    var bundleName: String?
    if let cfBundleName = bundle.infoDictionary?["CFBundleName"] as? String {
      bundleName = cfBundleName
    } else if let cfBundleDisplayname = bundle.infoDictionary?["CFBundleDisplayName"] as? String {
      bundleName = cfBundleDisplayname
    }

    guard let resolvedBundleName = bundleName else { return nil }

    let keys = ["CFBundleIconFile", "CFBundleIconName"]
    guard checkDictionary(dictionary: infoDictionary, for: keys) else { return nil }

    return Application(bundleIdentifier: bundleIdentifier,
                       bundleName: resolvedBundleName,
                       path: bundle.bundlePath)
  }

  private func checkDictionary(dictionary: [String: Any], for keys: [String]) -> Bool {
    let lhs = Set<String>(dictionary.keys)
    let rhs = Set<String>(keys)
    return !lhs.isDisjoint(with: rhs)
  }
}
