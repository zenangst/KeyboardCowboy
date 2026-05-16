import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

@Test func parseStringToResults() {
  let parser = ShellScript.Parser()
  do {
    let source = "yabai"
    #expect(parser.parse(source) == [.shell(source)])
  }

  do {
    let source = "/opt/homebrew/bin/yabai"
    #expect(parser.parse(source) == [.headless(source)])
  }

  do {
    let source = "ls -la; /opt/homebrew/bin/yabai"
    #expect(parser.parse(source) == [
      .shell("ls -la"),
      .headless("/opt/homebrew/bin/yabai"),
    ])
  }

  do {
    let source = "/opt/homebrew/bin/yabai;/opt/homebrew/bin/yabai"
    #expect(parser.parse(source) == [
      .headless("/opt/homebrew/bin/yabai"),
      .headless("/opt/homebrew/bin/yabai"),
    ])
  }

  do {
    let source = "/opt/homebrew/bin/yabai; yabai;/opt/homebrew/bin/yabai"
    #expect(parser.parse(source) == [
      .headless("/opt/homebrew/bin/yabai"),
      .shell("yabai"),
      .headless("/opt/homebrew/bin/yabai"),
    ])
  }
}

@Test func parseResultsToProcessComponents() {
  let parser = ShellScript.Parser()

  do {
    let result = ShellScript.Parser.Result.headless("/opt/homebrew/bin/yabai -m window --toggle split")
    #expect(parser.parse([result]) == [
      ShellScript.Parser.ProcessComponents(
        arguments: ["-m", "window", "--toggle", "split"],
        executableURL: URL(filePath: "/opt/homebrew/bin/yabai"),
        result: result,
      ),
    ])
  }

  do {
    let result = ShellScript.Parser.Result.shell("yabai -m window --toggle split")
    #expect(parser.parse([result]) == [
      ShellScript.Parser.ProcessComponents(
        arguments: ["-m", "window", "--toggle", "split"],
        executableURL: URL(filePath: "yabai"),
        result: result,
      ),
    ])
  }
}
