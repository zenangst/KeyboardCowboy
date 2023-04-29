import Foundation
import SwiftUI

struct AppStorageStore {
  #if DEBUG
  @AppStorage("selectedConfiguration", store: UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.debug")) var configId: String = ""
  @AppStorage("selectedGroupIds", store: UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.debug")) var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds", store: UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.debug")) var workflowIds = Set<String>()
  @AppStorage("responderId", store: UserDefaults(suiteName: "com.zenangst.Keyboard-Cowboy.debug")) var responderId: String = ""

  #else
  @AppStorage("selectedConfiguration") var configId: String = ""
  @AppStorage("selectedGroupIds") var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds") var workflowIds = Set<String>()
  @AppStorage("responderId") var responderId: String = ""
  #endif
}
