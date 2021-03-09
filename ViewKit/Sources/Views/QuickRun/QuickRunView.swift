import Cocoa
import SwiftUI
import ModelKit
import MbSwiftUIFirstResponder

public struct QuickRunView: View {
  public enum FirstResponder: Int {
    case textField
  }

  public enum Action {
    case run(String?)
  }

  public var window: EventWindow
  @Binding var firstResponder: FirstResponder?
  @Binding var query: String
  @ObservedObject var viewController: QuickRunViewController
  @State private var selection: String?

  public init(firstResponder: Binding<FirstResponder?>,
              query: Binding<String>,
              viewController: QuickRunViewController,
              window: EventWindow) {
    _firstResponder = firstResponder
    _query = query
    _viewController = ObservedObject(wrappedValue: viewController)
    self.window = window
  }

  public var body: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        HStack {
          Image("ApplicationIcon")
            .resizable()
            .frame(width: 48, height: 48, alignment: .center)

          TextField("", text: $query)
            .firstResponder(id: FirstResponder.textField, firstResponder: $firstResponder)
            .foregroundColor(.primary)
            .textFieldStyle(PlainTextFieldStyle())
            .colorMultiply(Color.accentColor)
            .introspectTextField { textField in
              textField.focusRingType = .none
            }
        }
        .font(.largeTitle)
        .padding(.horizontal)
        .padding(.vertical, 8)
        Divider()
        List(selection: $selection) {
          ForEach(viewController.state, id: \.id) { workflow in
            DeferView {
              WorkflowListView(workflow: workflow)
            }
            .tag(workflow.id)
            .onTapGesture {
              selection = workflow.id
              viewController.perform(.run(workflow.id))
            }
          }
        }
      }
      .ignoresSafeArea(.container, edges: .top)
      .frame(minWidth: 300)
      .onReceive(window.keyEventPublisher, perform: { event in
        keyPressed(with: event, scrollViewProxy: proxy)
      })
      .animation(.none)
    }
  }

  public func focusOnTextField() {
    firstResponder = .textField
  }

  func keyPressed(with event: NSEvent, scrollViewProxy: ScrollViewProxy) {
    guard !viewController.state.isEmpty,
          let keyCode = KeyCode(rawValue: event.keyCode) else { return }

    var offset: Int = 0

    if self.selection == nil {
      selection = viewController.state.first?.id
      offset = -1
    }

    if let selection = selection,
       var index = viewController.state.firstIndex(where: { $0.id == selection }) {
      index += offset
      let newIndex: Int
      switch keyCode {
      case .arrowUp:
        newIndex = max(index - 1, 0)
        firstResponder = index == newIndex ? .textField : nil
      case .arrowDown:
        newIndex = max(min(index + 1, viewController.state.count - 1), 0)
        firstResponder = nil
      case .enter:
        viewController.perform(.run(selection))
        fallthrough
      case .escape:
        firstResponder = .textField
        window.close()
        self.selection = nil
        return
      }

      let newSelection = viewController.state[newIndex].id
      self.selection = newSelection

      withAnimation {
        scrollViewProxy.scrollTo(newSelection, anchor: .top)
      }
    }
  }
  }

private enum KeyCode: UInt16 {
  case enter = 36
  case escape = 53
  case arrowUp = 126
  case arrowDown = 125
}

struct QuickRunStack_Previews: PreviewProvider {
  static var previews: some View {
    QuickRunView(
      firstResponder: .constant(nil),
      query: .constant("Open Mail Workflow"),
      viewController: QuickRunPreviewViewController().erase(),
      window: MockWindow())
      .frame(width: 420, alignment: .center)
  }
}
