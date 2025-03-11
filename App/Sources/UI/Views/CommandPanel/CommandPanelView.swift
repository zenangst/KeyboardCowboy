import Bonzai
import SwiftUI

@MainActor
final class CommandPanelViewPublisher: ObservableObject {
  @MainActor
  @Published private(set) var state: CommandPanelView.CommandState

  @MainActor
  init(state: CommandPanelView.CommandState = .ready) {
    self.state = state
  }

  @MainActor
  func publish(_ newState: CommandPanelView.CommandState) {
    self.state = newState
  }
}

struct CommandPanelView: View {
  enum CommandState: Hashable, Equatable {
    case ready
    case running
    case error(String)
    case done(String)
  }

  @ObservedObject var publisher: CommandPanelViewPublisher
  @State var output: String = ""

  @State var command: ScriptCommand
  let onChange: (String) -> Void
  let onSubmit: (ScriptCommand) -> Void
  let action: () -> Void

  init(publisher: CommandPanelViewPublisher,
       command: ScriptCommand,
       onChange: @escaping (String) -> Void,
       onSubmit: @escaping (ScriptCommand) -> Void,
       action: @escaping () -> Void) {
    self.command = command
    self.publisher = publisher
    self.onChange = onChange
    self.onSubmit = onSubmit
    self.action = action
  }

  var body: some View {
    VStack(spacing: 0) {
      CommandPanelHeaderView(
        state: publisher.state,
        name: command.name,
        action: action
      )
      .roundedStyle(padding: 4)

      ScrollView {
        VStack(spacing: 8) {
          switch command.source {
          case .path(let source):
            let viewModel = CommandViewModel.Kind.ScriptModel(
              id: command.id,
              source: .path(source),
              scriptExtension: command.kind,
              variableName: "",
              execution: .concurrent
            )
            ScriptCommandContentView(metaData: .init(name: "Name", namePlaceholder: ""), model: viewModel, onSubmit: {
              onSubmit(command)
            })
              .roundedStyle(padding: 4)
          case .inline(let source):
            let viewModel = CommandViewModel.Kind.ScriptModel(
                id: command.id,
                source: .inline(source),
                scriptExtension: command.kind,
                variableName: "",
                execution: .concurrent
            )
            ScriptCommandContentView(metaData: .init(name: "Name", namePlaceholder: ""), model: viewModel, onSubmit: {
              onSubmit(command)
            })
            .roundedStyle(padding: 4)
          }

          CommandPanelOutputView(state: publisher.state)
            .frame(maxWidth: .infinity)
            .roundedStyle(padding: 4)
        }
      }
    }
    .roundedStyle(padding: 8)
    .frame(minWidth: 200, minHeight: 200)
  }

  @MainActor
  static func preview(_ state: CommandPanelView.CommandState, command: ScriptCommand) -> some View {
    let publisher = CommandPanelViewPublisher(state: state)
    return CommandPanelView(publisher: publisher, command: command, onChange: { _ in }, onSubmit: { _ in }) {
      switch publisher.state {
      case .ready:   publisher.publish(.running)
      case .running: publisher.publish(.error("ops!"))
      case .error:   publisher.publish(.done("done"))
      case .done:    publisher.publish(.ready)
      }
    }
    .padding()
  }
}

private struct CommandPanelHeaderView: View {
  let state: CommandPanelView.CommandState
  let name: String
  let action: () -> Void

  var body: some View {
    HStack {
      ScriptIconView(size: 24)
      Text(name)
        .font(.headline)
      Spacer()
      Button(action: action,
             label: {
        Text(Self.buttonText(state))
          .frame(minWidth: 80)
      })
      .environment(\.buttonBackgroundColor, Self.buttonColor(state))
      .fixedSize()
      .animation(.easeIn, value: state)
    }
  }

  private static func buttonColor(_ state: CommandPanelView.CommandState) -> Color {
    switch state {
    case .ready: Color(.systemGray)
    case .running: .accentColor
    case .error: Color(.systemRed)
    case .done: Color(.systemGreen)
    }
  }

  private static func buttonText(_ state: CommandPanelView.CommandState) -> String {
    switch state {
    case .ready: "Run"
    case .running: "Cancel"
    case .error: "Run again…"
    case .done: "Run"
    }
  }
}

private struct CommandPanelOutputView: View {
  let state: CommandPanelView.CommandState

  var body: some View {
      switch state {
      case .ready:
        Color.clear
      case .running:
        ProgressView()
          .padding()
      case .error(let contents):
        CommandPanelErrorView(contents: contents)
      case .done(let contents):
        CommandPanelSuccessView(contents: contents)
      }
  }
}

private struct CommandPanelErrorView: View {
  let contents: String

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 4) {
          Text("[Exit Code]")
          ZenDivider(.vertical)
          Text("Error Message")
            .frame(maxWidth: .infinity, alignment: .leading)
          ErrorIconView(size: 16)
        }
        .font(.headline)
        .padding(8)
        .background(
          LinearGradient(stops: [
            .init(color: Color(.systemRed).opacity(0.4), location: 0),
            .init(color: Color(.systemRed.withSystemEffect(.disabled)).opacity(0.2), location: 1),
          ], startPoint: .top, endPoint: .bottom)
        )
        ZenDivider()
        Text(contents)
          .textSelection(.enabled)
          .fontDesign(.monospaced)
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(.callout))
          .padding(8)
      }
    }
  }
}

private struct CommandPanelSuccessView: View {
  private let searchSets = [
    SearchSet(regexPattern: { _ in "\\{|\\}|\\[|\\]|\"" },
              color: Color(.controlAccentColor.withSystemEffect(.pressed))),
    SearchSet(regexPattern: { _ in "\\d+" },
              color: Color(.systemRed.withAlphaComponent(0.7))),
  ]

  let contents: String
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 4) {
        Text("Result")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .font(.headline)
      .padding(8)
      .background(
        LinearGradient(stops: [
          .init(color: Color(.systemGreen).opacity(0.2), location: 0),
          .init(color: Color(.systemGreen.withSystemEffect(.disabled)).opacity(0.1), location: 1),
        ], startPoint: .top, endPoint: .bottom)
      )

      ZenDivider()

      Text(AttributedString(contents).syntaxHighlight(searchSets: searchSets).linkDetector(contents))
        .textSelection(.enabled)
        .allowsTightening(true)
        .fontDesign(.monospaced)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(.callout))
        .padding(8)
    }
  }
}

let prCommand = ScriptCommand(
  kind: .shellScript,
  source: .inline("gh pr ls"),
  meta: .init(name: "This is a script")
)

let prCommandResult = """
Showing 1 of 1 open pull request in zenangst/KeyboardCowboy

ID    TITLE                          BRANCH                         CREATED AT
#453  Feature Keyboard Cowboy stats  feature/keyboard-cowboy-stats  about 4 months ago
"""

let prCommandWithJQ = ScriptCommand(
  kind: .shellScript,
  source: .inline("gh pr ls --json url,title,number,headRefName,reviewDecision,changedFiles,deletions"),
  meta: .init(name: "Run GitHub CLI with jq")
)

let prCommandWithJQResult = """
[
  {
  "changedFiles": 2,
  "deletions": 0,
  "headRefName": "feature/keyboard-cowboy-stats",
  "number": 453,
  "reviewDecision": "",
  "title": "Feature Keyboard Cowboy stats",
  "url": "https://github.com/zenangst/KeyboardCowboy/pull/453"
  }
]
"""

#Preview("gh pr ls - with JQ") { CommandPanelView.preview(.done(prCommandWithJQResult), command: prCommandWithJQ) }
#Preview("gh pr ls") { CommandPanelView.preview(.done(prCommandResult), command: prCommand) }
#Preview("Error") { CommandPanelView.preview(.error("Oh shit!"), command: prCommand) }
#Preview("Ready") { CommandPanelView.preview(.ready, command: prCommand) }

extension AttributedString {
  func linkDetector(_ originalString: String) -> AttributedString {
    var attributedString = self

    let types = NSTextCheckingResult.CheckingType.link.rawValue

    guard let detector = try? NSDataDetector(types: types) else {
      return attributedString
    }

    let matches = detector.matches(
      in: originalString,
      options: [],
      range: NSRange(location: 0, length: originalString.count)
    )

    for match in matches {
      let range = match.range
      let startIndex = attributedString.index(
        attributedString.startIndex,
        offsetByCharacters: range.lowerBound
      )
      let endIndex = attributedString.index(
        startIndex,
        offsetByCharacters: range.length
      )

      switch match.resultType {
      case .link:
        if let url = match.url {
          attributedString[startIndex..<endIndex].link = url
          attributedString[startIndex..<endIndex].foregroundColor = Color(nsColor: .controlAccentColor.withSystemEffect(.deepPressed))
        }
      default:
        continue
      }

    }
    return attributedString
  }
  func syntaxHighlight(searchSets: [SearchSet]) -> AttributedString {
    var attrInText: AttributedString = self

    searchSets.forEach { searchSet in
      searchSet.words?.forEach({ word in
        guard let regex = try? Regex<Substring>(searchSet.regexPattern(word))
        else {
          fatalError("Failed to create regular expession")
        }
        processMatches(attributedText: &attrInText,
                       regex: regex,
                       color: searchSet.color)
      })
    }

    return attrInText
  }

  private func processMatches(attributedText: inout AttributedString,
                              regex: Regex<Substring>,
                              color: Color) {
    let orignalText: String = (
      attributedText.characters.compactMap { c in
        String(c)
      } as [String]).joined()

    orignalText.matches(of: regex).forEach { match in
      if let swiftRange = Range(match.range, in: attributedText) {
        attributedText[swiftRange].foregroundColor = NSColor(color)
      }
    }
  }
}

struct SearchSet {
  let words: [String]?
  let regexPattern: (String) -> String
  let color: Color

  init(words: [String]? = nil,
       regexPattern: @escaping (String) -> String,
       color: Color) {
    self.words = words ?? [""]
    self.regexPattern = regexPattern
    self.color = color
  }
}
