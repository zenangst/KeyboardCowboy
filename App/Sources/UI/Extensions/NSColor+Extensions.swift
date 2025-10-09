import Cocoa

extension NSColor {
  convenience init(hex string: String) {
    var hex = string.hasPrefix("#")
      ? String(string.dropFirst())
      : string
    guard hex.count == 3 || hex.count == 6
    else {
      self.init(red: 255, green: 255, blue: 255, alpha: 1.0)
      return
    }

    if hex.count == 3 {
      for (index, char) in hex.enumerated() {
        let offset = index * 2
        hex.insert(char, at: hex.index(hex.startIndex, offsetBy: offset))
      }
    }

    guard let intCode = Int(hex, radix: 16) else {
      self.init(red: 255, green: 255, blue: 255, alpha: 1.0)
      return
    }

    let red = Double((intCode >> 16) & 0xFF)
    let green = Double((intCode >> 8) & 0xFF)
    let blue = Double(intCode & 0xFF)

    self.init(
      red: red / 255.0,
      green: green / 255.0,
      blue: blue / 255.0,
      alpha: 1.0,
    )
  }
}
