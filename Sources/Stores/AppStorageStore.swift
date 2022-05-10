import Foundation
import SwiftUI

struct AppStorageStore {
  @AppStorage("selectedConfiguration") var configId: String = ""
  @AppStorage("selectedGroupIds") var groupIds = Set<String>()
  @AppStorage("selectedWorkflowIds") var workflowIds = Set<String>()
  @AppStorage("responderId") var responderId: String = ""
}
