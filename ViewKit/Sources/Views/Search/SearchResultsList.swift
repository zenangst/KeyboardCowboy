import Foundation
import ModelKit

public struct SearchResultsList {
  public enum Action {
    case search(String)
    case selectWorkflow(Workflow)
    case selectCommand(Command)
  }
}
