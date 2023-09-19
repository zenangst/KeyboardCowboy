import Foundation

struct ContextualTrigger: Identifiable, Codable {
  enum Condition: Codable {
    case wifi(info: Wifi)
//    case bluetooth
    case battery(info: Battery)
//    case power
//    case time
//    case location
//    case screen
//    case sleep
//    case wake
//    case calendar
//    case event
//    case reminder
//    case user
//    case none
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
