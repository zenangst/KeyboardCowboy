import Foundation

enum EncodableError: Error {
  case unableToEncodeAsString
}

extension Encodable {
  func toString() throws -> String {
    let data = try JSONEncoder().encode(self)
    guard let result = String(data: data, encoding: .utf8) else {
      throw EncodableError.unableToEncodeAsString
    }
    return result
  }
}
