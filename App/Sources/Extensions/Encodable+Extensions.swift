import Foundation

extension Encodable {
  func asString() throws -> String  {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(self)
    guard let string = String(data: data, encoding: .utf8) else {
      return ""
    }
    return string
  }
}
