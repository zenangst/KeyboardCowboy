@testable import ProcessSystem
@testable import CowboyCore
import Foundation
@testable import ScriptingFeature
import Testing

@Test func buildMixedInlineSourceAsOneShellScript() throws {
  try Core.ProcessInfo.Testing.$mock.withValue(["FOO": "BAR"], operation: {
    let builder = ShellScript.Builder(.testing)
    let input = "/opt/homebrew/bin/yabai -m window --space  1; /opt/homebrew/bin/yabai -m space --focus 1"
    let results = try builder.build(input)

    #expect(results.count == 1)
    #expect(results[0].executableURL == URL(filePath: "/bin/zsh"))
    #expect(results[0].arguments == ["-i", "-l"])
    #expect(results[0].environment?["PATH"]?.contains("homebrew") == true)
    #expect(results[0].environment?["TERM"] == "xterm-256color")
    #expect(results[0].environment?["FOO"] == "BAR")
    #expect(results[0].source == input)
  })
}

@Test func buildProcessShell() throws {
  try Core.ProcessInfo.Testing.$mock.withValue(["FOO": "BAR"], operation: {
    let builder = ShellScript.Builder(.testing)
    let input = "yabai -m window --space  1"
    let results = try builder.build(input)

    #expect(results.count == 1)

    #expect(results[0].executableURL == URL(filePath: "/bin/zsh"))
    #expect(results[0].arguments == ["-i", "-l"])
    #expect(results[0].environment?["PATH"]?.contains("homebrew") == true)
    #expect(results[0].environment?["TERM"] == "xterm-256color")
    #expect(results[0].environment?["FOO"] == "BAR")
    #expect(results[0].source == input)
  })
}

@Test func buildProcessShellWithShebang() throws {
  try Core.ProcessInfo.Testing.$mock.withValue(["FOO": "BAR"], operation: {
    let builder = ShellScript.Builder(.testing)
    let input = """
    #!/bin/bash

    yabai -m window --space  1
    """
    let results = try builder.build(input)

    #expect(results.count == 1)

    #expect(results[0].executableURL == URL(filePath: "/bin/bash"))
    #expect(results[0].arguments == [])
    #expect(results[0].environment?["PATH"]?.contains("homebrew") == true)
    #expect(results[0].environment?["TERM"] == "xterm-256color")
    #expect(results[0].environment?["FOO"] == "BAR")
    #expect(results[0].source == input)
  })
}
