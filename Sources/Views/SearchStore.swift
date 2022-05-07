import Combine
import Foundation

final class SearchStore: ObservableObject {
  private var subscription: AnyCancellable?
  @Published private(set) var results: [SearchResult] = .init()

  init(_ results: [SearchResult]) {
    _results = .init(initialValue: results)
  }

  func subscribe(to publisher: Published<String>.Publisher) {
    subscription = publisher
      .sink(receiveValue: { [weak self] query in
        guard let self = self else { return }

        guard query.isEmpty else {
          self.results = []
          return
        }

        self.search(query)
      })
  }

  func search(_ query: String) {
    
  }
}
