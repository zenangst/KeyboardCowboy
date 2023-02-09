import Foundation

extension Array<Encodable> {
  func asString() throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    var output = "[\n"
    let elementCount = self.count
    for (offset, element) in self.enumerated() {
      let string = try element.asString()
      output += string
      if offset != elementCount - 1 {
        output += ","
      }
    }
    output += "\n]"

    return output
  }
}

extension Encodable {
  func data() throws -> Data {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    return data
  }

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
