import Foundation
import SwiftUI

struct AppStorageStore {
  #if DEBUG
  static let store = UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.debug")
  #else
  static let store = UserDefaults.standard
  #endif

  @AppStorage("selectedConfiguration", store: Self.store) var configId: String = ""
  @AppStorage("selectedGroupIds", store: Self.store) var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds", store: Self.store) var workflowIds = Set<String>()
}
