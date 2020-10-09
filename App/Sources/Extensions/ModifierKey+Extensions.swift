import ViewKit
import LogicFramework

extension ViewKit.ModifierKey {
  var swapNamespace: LogicFramework.ModifierKey {
    LogicFramework.ModifierKey(rawValue: self.rawValue)!
  }
}

extension LogicFramework.ModifierKey {
  var swapNamespace: ViewKit.ModifierKey {
    ViewKit.ModifierKey(rawValue: self.rawValue)!
  }
}

extension Collection where Element == ViewKit.ModifierKey {
  var swapNamespace: [LogicFramework.ModifierKey] {
    compactMap { $0.swapNamespace }
  }
}

extension Collection where Element == LogicFramework.ModifierKey {
  var swapNamespace: [ViewKit.ModifierKey] {
    compactMap { $0.swapNamespace }
  }
}
