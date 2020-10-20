import Foundation
import ModelKit
import ViewKit

class SearchGroupsController: StateController {
  @Published var state = ModelKit.SearchResult.groups([])
}
