import Combine
import Foundation

final class AutoCompletionStore: ObservableObject {
  @Published var completions: [String] = [String]()
  @Published var selection: String?

  init(_ completions: [String], selection: String?) {
    _completions = .init(initialValue: completions)
    _selection = .init(initialValue: selection)
  }
}
