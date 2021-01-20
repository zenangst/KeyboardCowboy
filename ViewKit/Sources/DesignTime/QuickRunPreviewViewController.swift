import Cocoa
import Combine
import ModelKit

final class QuickRunPreviewViewController: ViewController {
  let state: [Workflow] = ModelFactory().workflowList()
  func perform(_ action: QuickRunView.Action) {}
}

class MockWindow: NSWindow, EventWindow {
  private let publisher = PassthroughSubject<NSEvent, Never>()
  var keyEventPublisher: AnyPublisher<NSEvent, Never> {
    publisher.eraseToAnyPublisher()
  }
}
