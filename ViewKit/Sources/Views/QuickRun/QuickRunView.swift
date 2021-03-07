import Cocoa
import SwiftUI
import ModelKit
import MbSwiftUIFirstResponder

public struct QuickRunView: View {
  enum FirstResponders: Int {
    case textField
  }

  public enum Action {
    case run(String?)
  }

  public var window: EventWindow
  @Binding var shouldActivate: Bool
  @Binding var query: String
  @ObservedObject var viewController: QuickRunViewController
  @State private var selection: String?
  @State private var firstResponder: FirstResponders? = .textField

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
    ScrollViewReader { proxy in
      VStack(spacing: 0) {
        HStack {
          Image("ApplicationIcon")
            .resizable()
            .frame(width: 48, height: 48, alignment: .center)

          TextField("", text: $query)
            .firstResponder(id: FirstResponders.textField, firstResponder: $firstResponder)
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

  func keyPressed(with event: NSEvent, scrollViewProxy: ScrollViewProxy) {
    guard !viewController.state.isEmpty,
          let keyCode = KeyCode(rawValue: event.keyCode) else { return }

    if self.selection == nil {
      selection = viewController.state.first?.id
    }

    if let selection = selection,
       let index = viewController.state.firstIndex(where: { $0.id == selection }) {
      let newIndex: Int
      switch keyCode {
      case .enter:
        viewController.perform(.run(selection))
        firstResponder = .textField
        return
      case .arrowUp:
        newIndex = max(index - 1, 0)
        firstResponder = nil
      case .arrowDown:
        newIndex = max(min(index + 1, viewController.state.count - 1), 0)
        firstResponder = nil
      case .escape:
        window.close()
        firstResponder = .textField
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
      shouldActivate: .constant(true),
      query: .constant("Open Mail Workflow"),
      viewController: QuickRunPreviewViewController().erase(),
      window: MockWindow())
      .frame(width: 420, alignment: .center)
  }
}
