import Cocoa
import CowboyCore
import Foundation

public extension ShellScript {
  private typealias ProcessComponent = ShellScript.Parser.ProcessComponents

  final class Builder {
    private let env: Core.Environment

    init(_ env: Core.Environment) {
      self.env = env
    }

    func build(_ source: String) throws -> [Core.Process] {
      let parser = Parser()
      let results = parser.parse(source)
      let components = parser.parse(results)
      let output = try components.map { component in
        return switch component.result {
        case .headless: buildHeadless(component)
        case .shell: try buildShell(component)
        }
      }

      return output
    }

    // MARK: Private methods

    private func buildHeadless(_ component: ProcessComponent) -> Core.Process {
      let process = Process(env, result: component.result)

      setEnvironment(on: process)

      process.executableURL = component.executableURL
      process.arguments = component.arguments

      return process
    }

    private func buildShell(_ component: ProcessComponent) throws -> Process {
      let process = Process(env, result: component.result)

      setEnvironment(on: process)

      let hasShebang = process.source.hasPrefix("#!")
      let arguments: [String]
      let executableURL: URL
      let fallbackShell = ProcessInfo.environment(env)["SHELL", default: "/bin/zsh"]

      if hasShebang, let firstLine = process.source.split(separator: "\n").first {
        let interpreterLine = firstLine.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = interpreterLine.split(separator: " ").map(String.init)

        if let interpreter = tokens.first {
          executableURL = URL(filePath: interpreter)
          arguments = Array(tokens.dropFirst())
        } else {
          executableURL = URL(filePath: fallbackShell)
          arguments = ["-i", "-l"]
        }
      } else {
        executableURL = URL(filePath: fallbackShell)
        arguments = ["-i", "-l"]
      }

      process.executableURL = executableURL
      process.arguments = arguments

      return process
    }

    private func setEnvironment(on process: Process) {
      var environment = ProcessInfo.environment(env)

      environment["PATH"] = "/usr/local/bin:/opt/homebrew/bin:" + (environment["PATH"] ?? "")
      environment["SHELL"] = ProcessInfo.environment(env)["SHELL", default: "/bin/zsh"]
      environment["TERM"] = "xterm-256color"

      process.environment = environment
    }
  }
}
