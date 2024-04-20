import Foundation

enum CommandLineAction: Codable, Identifiable, Hashable, Sendable {
  var id: String {
    switch self {
    case .argument(let contents): contents
    }
  }

  case argument(contents: String)
}
