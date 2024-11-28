import Foundation

@objc protocol XPCServiceProtocol {
  func helloWorld(string: String, withReply reply: @Sendable @escaping (String) -> Void)
}
