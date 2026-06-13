import CowboyCore
import Foundation

extension ShellScript {
  final class Parser {
    // enum Result: Equatable {
    //   case shell(String)
    //   case headless(String)

    //   var source: String {
    //     switch self {
    //     case .shell(let string): string
    //     case .headless(let string): string
    //     }
    //   }
    // }

    struct ProcessComponents: Equatable {
      let arguments: [String]
      let executableURL: URL
      let launchStyle: Core.Process.LaunchStyle
    }

    func parse(_ source: String) -> [Core.Process.LaunchStyle] {
      if source.hasPrefix("#!") {
        [.shell(source)]
      } else {
        source
          .split(separator: ";")
          .map {
            let string = (String($0).trimmingCharacters(in: .whitespaces) as NSString)
              .expandingTildeInPath
            return string.hasPrefix("/")
              ? .headless(string)
              : .shell(string)
          }
      }
    }

    func parse(_ launchStyles: [Core.Process.LaunchStyle]) -> [ProcessComponents] {
      launchStyles.compactMap { launchStyle in
        let strings = launchStyle.source
          .split(separator: " ")
          .map(String.init)

        guard let executablePath = strings.first else {
          return nil
        }

        let arguments: [String] = strings.suffix(strings.count - 1)
        var sanitizedPath = (executablePath as NSString).expandingTildeInPath
        sanitizedPath = sanitizedPath.replacingOccurrences(of: "", with: "\\ ")

        return ProcessComponents(
          arguments: arguments,
          executableURL: URL(fileURLWithPath: sanitizedPath),
          launchStyle: launchStyle,
        )
      }
    }
  }
}
