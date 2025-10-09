import Foundation
import SwiftUI

final class MouseModel: ObservableObject {
  @Published var rect: CGRect = .zero
}

@MainActor
final class MouseWindowController {
  static let shared = MouseWindowController()

  private var model: MouseModel
  private var windowController: NSWindowController

  init() {
    let model = MouseModel()
    let window = NotificationWindow(
      animationBehavior: .none,
      content: MouseView(model: model),
    )
    self.model = model
    windowController = NSWindowController(window: window)
  }

  func post(_ rect: CGRect) {
    model.rect = rect
    windowController.showWindow(nil)
  }
}

struct MouseView: View {
  @EnvironmentObject var manager: WindowManager
  @ObserveInjection var inject
  @ObservedObject var model: MouseModel

  var body: some View {
    GeometryReader { _ in
      Rectangle()
        .fill(Color.green.opacity(0.2))
        .overlay(
          Text("Location: \(model.rect.origin.x)x\(model.rect.origin.y)"),
        )
        .frame(width: model.rect.size.width, height: model.rect.size.height)
        .offset(x: model.rect.origin.x, y: model.rect.origin.y)
        .ignoresSafeArea(.all)
    }
    .allowsHitTesting(false)
    .enableInjection()
  }
}
