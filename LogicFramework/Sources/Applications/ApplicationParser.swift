import Cocoa
import Foundation
import ModelKit

final class ApplicationParser {
  /// Resolve an `Application` model from an application at a certain url.
  ///
  /// Parsing is done by invoking `Bundle(url:)` and verifying the contents
  /// of the applications property list.
  ///
  /// - Parameter url: The url of the application
  /// - Returns: A `Application` if all the validation critieras are met, otherwise
  ///            if will simply return `nil`
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

  /// Verify existence of certain keys, only one of the keys must match
  /// the dictionary that is used as the subject for validation.
  ///
  /// - Parameters:
  ///   - dictionary: The dictionary that should be validated
  ///   - keys: An array of keys that should be used for validation
  /// - Returns: Only one of the keys must match the dictionary in order for the method
  ///            to return true
  private func checkDictionary(dictionary: [String: Any], for keys: [String]) -> Bool {
    let lhs = Set<String>(dictionary.keys)
    let rhs = Set<String>(keys)
    return !lhs.isDisjoint(with: rhs)
  }
}
