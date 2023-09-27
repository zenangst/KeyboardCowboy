import Foundation

struct ContextualTrigger: Identifiable, Codable {
  enum Condition: Codable {
    case wifi(info: Wifi)
    case battery(info: Battery)
  }

  struct Wifi: Codable {
    let id: String
    let ssid: String
  }

  struct Battery: Codable {
    let id: String
  }

  let id: String
  let conditions: [Condition]
}
