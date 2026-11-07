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
        return switch component.launchStyle {
        case .headless: buildHeadless(component)
        case .shell: try buildShell(component)
        }
      }

      return output
    }

    /// Builds a process for an existing script without copying or rewriting it.
    func buildFile(at path: String) -> Core.Process {
      let expandedPath = (path as NSString).expandingTildeInPath
      let contents = FileManager(env).contents(atPath: expandedPath)
        .flatMap { String(data: $0, encoding: .utf8) } ?? ""
      let process = Process(env, launchStyle: .headless(contents))
      setEnvironment(on: process)
      configureShell(process, source: contents)
      let name = (expandedPath as NSString).lastPathComponent
      process.arguments?.append(name.hasPrefix("-") ? "./\(name)" : name)
      process.currentDirectoryURL = URL(fileURLWithPath: (expandedPath as NSString).deletingLastPathComponent)
      return process
    }

    // MARK: Private methods

    private func buildHeadless(_ component: ProcessComponent) -> Core.Process {
      let process = Process(env, launchStyle: component.launchStyle)

      setEnvironment(on: process)

      process.executableURL = component.executableURL
      process.arguments = component.arguments

      return process
    }

    private func buildShell(_ component: ProcessComponent) throws -> Process {
      let process = Process(env, launchStyle: component.launchStyle)

      setEnvironment(on: process)
      configureShell(process, source: process.source)
      return process
    }

    private func configureShell(_ process: Process, source: String) {
      let hasShebang = source.hasPrefix("#!")
      let arguments: [String]
      let executableURL: URL
      let fallbackShell = ProcessInfo.environment(env)["SHELL", default: "/bin/zsh"]

      if hasShebang, let firstLine = source.split(separator: "\n").first {
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
