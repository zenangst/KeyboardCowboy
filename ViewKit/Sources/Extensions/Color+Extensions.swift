import SwiftUI

extension Color {
  init(hex string: String) {
    var hex = string.hasPrefix("#")
      ? String(string.dropFirst())
      : string
    guard hex.count == 3 || hex.count == 6
    else {
      self.init(.white)
      return
    }
    if hex.count == 3 {
      for (index, char) in hex.enumerated() {
        hex.insert(char, at: hex.index(hex.startIndex, offsetBy: index * 2))
      }
    }

    guard let intCode = Int(hex, radix: 16) else {
      self.init(.white)
      return
    }

    self.init(
      red: Double((intCode >> 16) & 0xFF) / 255.0,
      green: Double((intCode >> 8) & 0xFF) / 255.0,
      blue: Double((intCode) & 0xFF) / 255.0,
      opacity: 1.0)
  }
}
