import Foundation
import ModelKit
import ViewKit
import SwiftUI
import Combine

class SearchGroupsController: StateController {
  @Published var state = ModelKit.SearchResult.groups([])
}
