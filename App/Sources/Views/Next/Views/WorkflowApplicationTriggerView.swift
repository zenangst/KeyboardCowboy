import Apps
import SwiftUI

struct WorkflowApplicationTriggerView: View {
  enum Action {
    case addApplicationTrigger(application: Application, uuid: UUID)
    case updateApplicationTriggerContext(DetailViewModel.ApplicationTrigger)
    case removeApplicationTrigger(DetailViewModel.ApplicationTrigger)
  }

  @ObserveInjection var inject
  @EnvironmentObject var applicationStore: ApplicationStore

  @State private var triggers: [DetailViewModel.ApplicationTrigger]
  @State private var selection: String = UUID().uuidString
  private let onAction: (Action) -> Void

  init(_ triggers: [DetailViewModel.ApplicationTrigger], onAction: @escaping (Action) -> Void) {
    _triggers = .init(initialValue: triggers)
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Menu("Add application") {
          ForEach(applicationStore.applications) { application in
            Button(action: {
              let uuid = UUID()
              onAction(.addApplicationTrigger(application: application, uuid: uuid))
              triggers.append(.init(id: uuid.uuidString, name: application.displayName,
                                    image: NSWorkspace.shared.icon(forFile: application.path),
                                    contexts: []))
            }, label: {
              Text(application.displayName)
            })
          }
        }
        .menuStyle(.automatic)
      }
      .padding(.horizontal, 4)

      EditableStack($triggers, lazy: true, spacing: 2, onMove: { _, _ in }) { trigger in
        HStack(spacing: 0) {
          Image(nsImage: trigger.image.wrappedValue)
            .resizable()
            .frame(width: 36, height: 36)
          VStack(alignment: .leading, spacing: 4) {
            Text(trigger.name.wrappedValue)
            HStack {
              ForEach(DetailViewModel.ApplicationTrigger.Context.allCases) { context in
                Toggle(context.displayValue, isOn: Binding<Bool>(get: {
                  trigger.contexts.wrappedValue.contains(context)
                }, set: { newValue in
                  if newValue {
                    trigger.contexts.wrappedValue.append(context)
                  } else {
                    trigger.contexts.wrappedValue.removeAll(where: { $0 == context })
                  }

                  onAction(.updateApplicationTriggerContext(trigger.wrappedValue))
                }))
                .font(.caption)
              }
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
          Spacer()
          Divider()
            .opacity(0.25)
          Button(
            action: {
              onAction(.removeApplicationTrigger(trigger.wrappedValue))
              if let index = triggers.firstIndex(of: trigger.wrappedValue) {
                triggers.remove(at: index)
              }
            },
            label: { Image(systemName: "xmark") })
          .buttonStyle(.appStyle)
          .padding(.horizontal, 8)
        }
        .padding(.leading, 8)
        .background(Color(.windowBackgroundColor).opacity(0.75))
        .cornerRadius(8)
        .shadow(radius: 2)
      }
    }
    .enableInjection()
  }
}
