import BridgeKit
import SwiftUI
import ModelKit

struct TriggerView: View {
  // swiftlint:disable weak_delegate
  @StateObject var transportDelegate = TransportDelegate()
  let context: ViewKitFeatureContext
  @State var selection: ModelKit.KeyboardShortcut?
  @Binding var workflow: Workflow

  var body: some View {
    VStack(alignment: .leading) {
      switch workflow.trigger {
      case .application(let triggers):
        HStack {
          HeaderView(title: "Application triggers:")
          Spacer()
          Button(action: {
            context.applicationTrigger.perform(.clear(workflow))
          }, label: {
            Image(systemName: "xmark.circle")
              .renderingMode(.template)
          })
          .buttonStyle(PlainButtonStyle())
        }
        .padding([.top])

        ApplicationTriggerList(workflow: workflow,
                               triggers: .constant(triggers),
                               context: context)
      case .keyboardShortcuts:
        HStack {
          HeaderView(title: "Keyboard shortcuts:")
          Spacer()
          Button(action: {
            context.keyboardsShortcuts.perform(.clear(workflow))
          }, label: {
            Image(systemName: "xmark.circle")
          })
          .buttonStyle(PlainButtonStyle())
        }.padding([.top])
        Divider().padding(.bottom)
        KeyboardShortcutList(workflow: $workflow,
                             performAction: context.keyboardsShortcuts.perform(_:))
      case .none:
        HeaderView(title: "Trigger:").padding([.top])
        HStack {
          Button("Application", action: addApplicationTrigger)
          Button("Keyboard Shortcut", action: addKeyboardShortcut)
        }
      }
    }
  }

  func addApplicationTrigger() {
    context.applicationTrigger.perform(.emptyTrigger(workflow))
  }

  func addKeyboardShortcut() {
    let newShortcut = ModelKit.KeyboardShortcut.empty()
    context.keyboardsShortcuts.perform(.create(newShortcut,
                                               offset: 9999,
                                               in: workflow))
    selection = newShortcut
    onTap()
  }

  func onTap() {
    TransportController.shared.receiver = transportDelegate
    NotificationCenter.default.post(.enableRecordingHotKeys)
  }
}

struct TriggerView_Previews: PreviewProvider {
  static let workflows = [
    ModelFactory().workflowDetail(trigger: nil),
    ModelFactory().workflowDetail(trigger: .application([.init(application: Application.finder(),
                                                               contexts: [.frontMost])])),
    ModelFactory().workflowDetail(trigger: .keyboardShortcuts(ModelFactory().keyboardShortcuts()))
  ]

  static var previews: some View {

    ForEach(workflows) { workflow in
      TriggerView(
        context: ViewKitFeatureContext.preview(),
        workflow: .constant(workflow)
      )
    }
  }
}
