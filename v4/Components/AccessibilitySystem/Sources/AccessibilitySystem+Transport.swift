import CoreGraphics
import Foundation

extension AccessibilitySystem {
  protocol Transport {
    func application(_ pid: Int32) -> Handle
    func focusedElement() throws -> Handle
    func element(at point: CGPoint) throws -> Handle
    func setTimeout(_ seconds: Float, on handle: Handle) throws
    func read(_ name: String, from handle: Handle) throws -> ReadValue
    func bounds(for range: NSRange, from handle: Handle) throws -> CGRect
    func perform(_ action: Action, on handle: Handle) throws
    func write(_ name: String, value: Bool, to handle: Handle) throws
    func write(_ name: String, value: String, to handle: Handle) throws
    func write(_ name: String, value: CGPoint, to handle: Handle) throws
    func write(_ name: String, value: CGSize, to handle: Handle) throws
  }
}
