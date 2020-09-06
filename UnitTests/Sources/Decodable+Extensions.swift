import Foundation

extension Decodable {
  static func decode(from jsonObject: Any) throws -> Self {
    let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    return try JSONDecoder().decode(Self.self, from: data)
  }
}
