import Foundation

enum CommandLineAction: Codable, Identifiable, Hashable, Sendable {
  var id: String {
    switch self {
    case let .argument(contents): contents
    }
  }

  case argument(contents: String)
}
