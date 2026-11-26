import CoreGraphics
import Foundation

extension AccessibilitySystem {
  enum ReadValue {
    case string(String)
    case bool(Bool)
    case url(URL)
    case element(Handle)
    case elements([Handle])
    case point(CGPoint)
    case size(CGSize)
    case range(NSRange)
    case rect(CGRect)
    case malformed
  }
}
