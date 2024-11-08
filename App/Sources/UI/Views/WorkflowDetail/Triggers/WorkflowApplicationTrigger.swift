import Apps
import Bonzai
import Inject
import SwiftUI

struct WorkflowApplicationTrigger: View {
  @ObserveInjection var inject
  @EnvironmentObject private var updater: ConfigurationUpdater
  @EnvironmentObject private var transaction: UpdateTransaction
  @EnvironmentObject private var applicationStore: ApplicationStore
  @ObservedObject private var selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  @State private var data: [DetailViewModel.ApplicationTrigger]
  @State private var selection: String = UUID().uuidString
  private var focus: FocusState<AppFocus?>.Binding
  private var onTab: () -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       data: [DetailViewModel.ApplicationTrigger],
       selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       onTab: @escaping () -> Void) {
    self.focus = focus
    _data = .init(initialValue: data)
    self.selectionManager = selectionManager
    self.onTab = onTab
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        GenericAppIconView(size: 28)
        Menu {
          Button(action: {
            let uuid = UUID()
            let anyApplication = Application.anyApplication()
            withAnimation(CommandList.animation) {
              data.append(.init(id: uuid.uuidString, name: anyApplication.displayName,
                                application: anyApplication, contexts: []))
            }
          }, label: {
            Text("Any Application")
          })

          ForEach(applicationStore.applications.lazy, id: \.path) { application in
            Button(action: {
              let uuid = UUID()
              withAnimation(CommandList.animation) {
                data.append(.init(id: uuid.uuidString, name: application.displayName,
                                  application: application, contexts: []))
              }
            }, label: {
              Text(application.displayName)
            })
          }
        } label: {
         Text("Add Application")
        }
        .menuStyle(.zen(.init(color: data.isEmpty ? .systemGreen : .systemBlue,
                              grayscaleEffect: Binding<Bool>.readonly(!data.isEmpty),
                              hoverEffect: Binding<Bool>.readonly(!data.isEmpty),
                              padding: .init(horizontal: .large, vertical: .large))))
      }
      .roundedContainer(padding: 6, margin: 0)
      .frame(minHeight: 44)

      if !data.isEmpty {
        let count = data.count
        ScrollView {
          LazyVStack(spacing: 0) {
            let lastID = $data.lazy.last?.id
            ForEach($data.lazy, id: \.id) { element in
              ApplicationTriggerItem(element, data: $data, selectionManager: selectionManager)
              .contentShape(Rectangle())
              .dropDestination(DetailViewModel.ApplicationTrigger.self, color: .accentColor, onDrop: { items, location in
                let ids = Array(selectionManager.selections)
                guard let (from, destination) = data.moveOffsets(for: element.wrappedValue, with: ids) else {
                  return false
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                  data.move(fromOffsets: IndexSet(from), toOffset: destination)
                }
                return false
              })
              .focusable(focus, as: .detail(.applicationTrigger(element.id))) {
                selectionManager.handleOnTap(data, element: element.wrappedValue)
              }

              let notLastItem = element.id != lastID
              ZenDivider()
                .opacity(notLastItem ? 1 : 0)
                .frame(height: notLastItem ? nil : 0)
            }
            .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
              onTab()
            })
            .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
              selectionManager.publish(Set(data.map(\.id)))
            })
            .onMoveCommand(perform: { direction in
              if let elementID = selectionManager.handle(direction, data, proxy: nil) {
                focus.wrappedValue = .detail(.applicationTrigger(elementID))
              }
            })
            .onDeleteCommand {
              let offsets = data.deleteOffsets(for: selectionManager.selections)
              withAnimation {
                data.remove(atOffsets: IndexSet(offsets))
              }
            }
          }
          .onChange(of: data, perform: { newValue in
            updateApplicationTriggers(newValue)
          })
          .focused(focus, equals: .detail(.applicationTriggers))
        }
        .scrollDisabled(count <= 3)
        .frame(minHeight: 46, maxHeight: maxHeight(count))
        .roundedContainer(12, padding: 2, margin: 0)
      }
    }
    .enableInjection()
  }

  private func updateApplicationTriggers(_ data: [DetailViewModel.ApplicationTrigger]) {
    updater.modifyWorkflow(using: transaction) { workflow in
      let applicationTriggers = data
        .map { trigger in
          var viewModelContexts = Set<DetailViewModel.ApplicationTrigger.Context>()
          let allContexts: [DetailViewModel.ApplicationTrigger.Context] = [.closed, .frontMost, .launched, .resignFrontMost]
          for context in allContexts {
            if trigger.contexts.contains(context) {
              viewModelContexts.insert(context)
            } else {
              viewModelContexts.remove(context)
            }
          }
          let contexts = viewModelContexts.map(\.appTriggerContext)
          return ApplicationTrigger(id: trigger.id, application: trigger.application, contexts: contexts)
        }

      workflow.trigger = .application(applicationTriggers)
    }
  }

  private func maxHeight(_ count: Int) -> CGFloat {
    if count > 1 {
      return min(CGFloat(count * 48), 300)
    } else {
      return 46 // Max size without the `ZenDivider`
    }
  }
}

fileprivate extension DetailViewModel.ApplicationTrigger.Context {
  var appTriggerContext: ApplicationTrigger.Context {
    switch self {
    case .launched:        .launched
    case .closed:          .closed
    case .frontMost:       .frontMost
    case .resignFrontMost: .resignFrontMost
    }
  }
}

#Preview {
  @FocusState var focus: AppFocus?
  return WorkflowApplicationTrigger(
    $focus,
    data: [
      .init(id: "1", name: "Application 1", application: .finder(),
            contexts: []),
    ],
    selectionManager: SelectionManager(),
    onTab: { }
  )
  .environmentObject(ApplicationStore.shared)
  .padding()
}
