import Combine
import Cocoa

final class AutoCompletion {
  var currentWord: String = ""
  let store: AutoCompletionStore
  let syntax: SyntaxHighlighting
  weak var textView: NSTextView?
  private(set) var storage = [String]()
  private var subscriptions = [AnyCancellable]()

  init(_ store: AutoCompletionStore, syntax: SyntaxHighlighting) {
    self.store = store
    self.syntax = syntax
  }

  func subscribeToIndex(to publisher: Published<String>.Publisher) {
    publisher
      .sink(receiveValue: { [weak self] text in
        self?.process(text)
      }).store(in: &subscriptions)
  }

  private func process(_ text: String) {
    guard !currentWord.isEmpty else { return }
    let charSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
    let words = text.components(separatedBy: charSet)
    var newStorage = syntax.keywords(textView!.font!)

    for word in newStorage {
      if word.lowercased().starts(with: currentWord.lowercased()) {
        newStorage.append(word)
      }
    }

    for word in words where !word.isEmpty && word.count >= currentWord.count {
      if !newStorage.contains(word) {
        newStorage.append(word)
      }
    }

    var processedCompletions = newStorage.sorted(by: {
      $0.levenshteinDistance(to: currentWord) < $1.levenshteinDistance(to: currentWord)
    })

    if processedCompletions.count > 4 {
      processedCompletions = Array(processedCompletions[0..<4])
    }

    storage = processedCompletions
    store.completions = processedCompletions
    store.selection = currentWord
  }
}

private extension String {
  func levenshteinDistance(to string: String, ignoreCase: Bool = true, trimWhiteSpacesAndNewLines: Bool = true) -> Int {
          var firstString = self
          var secondString = string

          if ignoreCase {
              firstString = firstString.lowercased()
              secondString = secondString.lowercased()
          }

          if trimWhiteSpacesAndNewLines {
              firstString = firstString.trimmingCharacters(in: .whitespacesAndNewlines)
              secondString = secondString.trimmingCharacters(in: .whitespacesAndNewlines)
          }

          let empty = [Int](repeating: 0, count: secondString.count)
          var last = [Int](0...secondString.count)

          for (i, tLett) in firstString.enumerated() {
              var cur = [i + 1] + empty
              for (j, sLett) in secondString.enumerated() {
                  cur[j + 1] = tLett == sLett ? last[j] : Swift.min(last[j], last[j + 1], cur[j]) + 1
              }

              last = cur
          }

          if let validDistance = last.last {
              return validDistance
          }

          assertionFailure()
          return 0
      }
}
