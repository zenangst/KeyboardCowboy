import Cocoa

struct ShellScriptHighlighting: SyntaxHighlighting {
  let id: String = "ShellScriptHighlighting"

  func highlights(_ font: NSFont) -> [Highlight] {
    [
      // Paths
      .init(#"(\/\w+)"#,
            attributes: [
              .font: font,
              .foregroundColor: NSColor.systemPink
                .withAlphaComponent(0.75)
                .blended(withFraction: 0.25, of: .white)!
            ]),
      // Shebang
      .init(#"(#[^\n]+)"#,
            attributes: [
              .font: font,
              .foregroundColor: NSColor.systemGreen
                .withAlphaComponent(0.75)
                .blended(withFraction: 0.25, of: .white)!
            ]),
      // Strings
      .init(#"("[^"]+")"#,
            attributes: [
              .font: font,
              .foregroundColor: NSColor.systemYellow
                .withAlphaComponent(0.75)
                .blended(withFraction: 0.25, of: .white)!
            ]),
      // Arguments
      .init(#"-{1,2}(\w+)|(|=[0-z]+)"#,
            attributes: [
              .font: font,
              .foregroundColor: NSColor.systemPurple
                .withAlphaComponent(0.75)
                .blended(withFraction: 0.25, of: .white)!
            ]),

    ]
  }
  func keywords(_ font: NSFont) -> [String] {
    [
      "bash",
      "sh",
      "zsh",
      "fish",
      "bin",
      "usr",
    ]
  }
}
