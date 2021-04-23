import SwiftUI
import ModelKit

public struct ApplicationTriggerList: View {
  public enum UIAction {
    case emptyTrigger(Workflow)
    case create(ModelKit.ApplicationTrigger, offset: Int, in: Workflow)
    case update(ModelKit.ApplicationTrigger, in: Workflow)
    case move(ModelKit.ApplicationTrigger, offset: Int, in: Workflow)
    case delete(ModelKit.ApplicationTrigger, in: Workflow)
    case clear(Workflow)
  }

  @State private var selectedApplicationIndex: Int = 0
  let workflow: Workflow
  @Binding var triggers: [ApplicationTrigger]
  private let context: ViewKitFeatureContext
  private let installedApplications: [Application]

  init(workflow: Workflow,
       triggers: Binding<[ApplicationTrigger]>,
       context: ViewKitFeatureContext,
       addApplication: @escaping (Application) -> Void = { _ in }) {
    self.workflow = workflow
    self._triggers = triggers
    self.context = context

    let bundleIdentifiers = triggers.wrappedValue.compactMap { $0.application.bundleIdentifier }
    self.installedApplications = context.applicationProvider.state
      .filter { !bundleIdentifiers.contains($0.bundleIdentifier) }
  }

  public var body: some View {
    VStack(alignment: .leading) {
      HStack {
        applicationView
        Button(action: {
          let application = installedApplications[selectedApplicationIndex]
          context.applicationTrigger.perform(.create(ApplicationTrigger(application: application,
                                                                        contexts: []), offset: 9999, in: workflow))
        }, label: {
          Text("Add application")
        })
        .disabled(selectedApplicationIndex == 0) // The first item doesn't have an application assigned.
      }

      Divider()

      HeaderView(title: "Applications:")

      ScrollView {
        VStack {
          ForEach(triggers) { trigger in
            HStack {
              ApplicationTriggerItem(trigger: Binding<ApplicationTrigger>(
                get: { trigger },
                set: { trigger in
                  context.applicationTrigger.perform(.update(trigger, in: workflow))
                }
              ))

              Button(action: {
                context.applicationTrigger.perform(.delete(trigger, in: workflow))
              }, label: {
                Image(systemName: "xmark.circle")
                  .renderingMode(.template)
              })
              .buttonStyle(PlainButtonStyle())
            }
          }
        }
      }
    }
  }

  var applicationView: some View {
    Group {
      VStack {
        Picker("", selection: $selectedApplicationIndex) {
          Text("Choose application …").tag(0)
          Divider()
          ForEach(1..<installedApplications.count, id: \.self) { index in
            Text(installedApplications[index].displayName).tag(index)
          }
        }
        .offset(x: -4.0, y: 0.0)
      }
    }
  }
}

struct ApplicationTriggerList_Previews: PreviewProvider {
  static var previews: some View {
    ApplicationTriggerList(
      workflow: ModelFactory().workflowDetail(trigger: nil),
      triggers:
        .constant([
          ApplicationTrigger(
            application: Application.finder(),
            contexts: [.frontMost]),
          ApplicationTrigger(
            application: Application.xcode(),
            contexts: [.launched, .closed])
        ]),
      context: ViewKitFeatureContext.preview())
  }
}
