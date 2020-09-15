import Foundation
import Carbon

/// Based on: https://github.com/Clipy/Sauce

extension TISInputSource {
  func value<T>(forProperty propertyKey: CFString, type: T.Type) -> T? {
    guard let value = TISGetInputSourceProperty(self, propertyKey) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(value).takeUnretainedValue() as? T
  }

  func value<T>(forProperty propertyKey: CFString, type: T.Type, defaultValue: T) -> T {
    guard let value = TISGetInputSourceProperty(self, propertyKey),
          let result = Unmanaged<AnyObject>.fromOpaque(value).takeUnretainedValue() as? T else { return defaultValue }
    return result
  }
}
