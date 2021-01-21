import Cocoa
import SwiftUI
import ModelKit
import Introspect

public struct QuickRunView: View {
  public enum Action {
    case run(String?)
  }

  public var window: EventWindow
  @Binding var shouldActivate: Bool
  @Binding var query: String
  @ObservedObject var viewController: QuickRunViewController

  @State private var selection: String?

  public init(shouldActivate: Binding<Bool>,
              query: Binding<String>,
              viewController: QuickRunViewController,
              window: EventWindow) {
    _shouldActivate = shouldActivate
    _query = query
    _viewController = ObservedObject(wrappedValue: viewController)
    self.window = window
  }

  public var body: some View {
    VStack(spacing: 0) {
      HStack {
        Image("ApplicationIcon")
          .resizable()
          .frame(width: 48, height: 48, alignment: .center)
        TextField("", text: $query, onCommit: {
          viewController.action(.run(selection))()
        })
          .foregroundColor(.primary)
          .textFieldStyle(PlainTextFieldStyle())
        .introspectTextField { textField in
          if self.shouldActivate {
            textField.becomeFirstResponder()
            self.shouldActivate = false
          }
          textField.focusRingType = .none
        }
      }
      .font(.largeTitle)
      .padding(.horizontal)
      .padding(.vertical, 8)
      Divider()
      List(selection: $selection) {
        ForEach(viewController.state, id: \.id) { workflow in
          WorkflowListView(workflow: workflow)
            .tag(workflow.id)
        }
      }.introspectTableView { tableView in
        tableView.isContinuous = true
      }
    }
    .ignoresSafeArea(.container, edges: .top)
    .frame(minWidth: 300)
    .onReceive(window.keyEventPublisher, perform: keyPressed(with:))
  }

  func keyPressed(with event: NSEvent) {
    guard !viewController.state.isEmpty,
          let keyCode = KeyCode(rawValue: event.keyCode) else { return }

    if let selection = selection,
       let index = viewController.state.firstIndex(where: { $0.id == selection }) {
      let newIndex: Int
      switch keyCode {
      case .arrowUp:
        newIndex = max(index - 1, 0)
      case .arrowDown:
        newIndex = max(min(index + 1, viewController.state.count - 1), 0)
      case .escape:
        window.close()
        return
      }

      let newSelection = viewController.state[newIndex].id
      self.selection = newSelection
    } else {
      selection = viewController.state.first?.id
    }
  }
}

private enum KeyCode: UInt16 {
  case escape = 53
  case arrowUp = 126
  case arrowDown = 125
}

struct QuickRunStack_Previews: PreviewProvider {
  static var previews: some View {
    QuickRunView(
      shouldActivate: .constant(true),
      query: .constant("Open Mail Workflow"),
      viewController: QuickRunPreviewViewController().erase(),
      window: MockWindow())
      .frame(width: 420, alignment: .center)
  }
}
