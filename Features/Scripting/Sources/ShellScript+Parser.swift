import Foundation

extension ShellScript {
  final class Parser {
    enum Result: Equatable {
      case shell(String)
      case headless(String)

      var source: String {
        switch self {
        case .shell(let string): string
        case .headless(let string): string
        }
      }
    }

    struct ProcessComponents: Equatable {
      let arguments: [String]
      let executableURL: URL
      let result: Result
    }

    func parse(_ source: String) -> [Result] {
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

    func parse(_ results: [Result]) -> [ProcessComponents] {
      results.compactMap { result in
        let strings = result.source
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
          result: result,
        )
      }
    }
  }
}
