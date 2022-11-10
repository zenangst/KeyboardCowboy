import SwiftUI

final class NavigationPublisher: ObservableObject {
  @Published var columnVisibility: NavigationSplitViewVisibility = .all
}
