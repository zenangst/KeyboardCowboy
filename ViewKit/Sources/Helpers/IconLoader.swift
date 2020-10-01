import SwiftUI

public protocol IconLoader: ObservableObject where ObjectWillChangePublisher.Output == Void {
  associatedtype State

  var icon: State { get }
}
