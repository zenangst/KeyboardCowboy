import Foundation
import ModelKit
import ViewKit

final class SearchGroupsController: StateController {
  @Published var state = ModelKit.SearchResult.groups([])
}
