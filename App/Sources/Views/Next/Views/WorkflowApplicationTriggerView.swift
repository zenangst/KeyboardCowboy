import Apps
import SwiftUI

struct WorkflowApplicationTriggerView: View {
  enum Action {
    case addApplicationTrigger(Application)
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
        Picker("", selection: $selection) {
          ForEach(applicationStore.applications, id: \.id) {
            Text($0.displayName)
              .tag($0.id)
          }
        }
        Spacer()
        Button(action: {
          if let application = applicationStore.application(for: selection) {
            onAction(.addApplicationTrigger(application))
          }
        },
               label: { Image(systemName: "plus") })
        .buttonStyle(AppButtonStyle())
        .padding(.leading, 10)
        .padding(.trailing, 16)
      }
      .padding(.horizontal, 4)
      .padding(.vertical)

      EditableStack($triggers, lazy: true, spacing: 2, onMove: { _, _ in }) { trigger in
        HStack {
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
                }))
                .font(.caption)
              }
            }
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
          Spacer()
          Divider()
            .opacity(0.5)
          Button(action: { onAction(.removeApplicationTrigger(trigger.wrappedValue)) },
                 label: { Image(systemName: "xmark") })
          .buttonStyle(AppButtonStyle())
          .padding(.leading, 8)
          .padding(.trailing, 12)
        }
        .padding(.horizontal, 8)
        .background(Color(.windowBackgroundColor).opacity(0.75))
        .cornerRadius(8)
        .shadow(radius: 2)
      }
      .cornerRadius(8)
    }
    .cornerRadius(8)
    .enableInjection()
  }
}
