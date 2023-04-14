import Combine
import Foundation
import ModelKit
import ViewKit

class HUDFeatureController: StateController {
  @Published var state = [KeyboardShortcut]()
}
