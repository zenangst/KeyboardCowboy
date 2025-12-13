import Apps
import Bonzai
import HotSwiftUI
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
       onTab: @escaping () -> Void)
  {
    self.focus = focus
    _data = .init(initialValue: data)
    self.selectionManager = selectionManager
    self.onTab = onTab
  }

  @MainActor
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Menu {
          Button(action: {
            let uuid = UUID()
            let anyApplication = Application.anyApplication()
            withAnimation(CommandList.animation) {
              data.append(.init(id: uuid.uuidString, name: anyApplication.displayName,
                                application: anyApplication, contexts: []))
              updateApplicationTriggers(data)
            }
          }, label: {
            Text("Any Application")
          })

          Divider()

          ForEach(applicationStore.applications.lazy, id: \.path) { application in
            Button(action: {
              let uuid = UUID()
              withAnimation(CommandList.animation) {
                data.append(.init(id: uuid.uuidString, name: application.displayName,
                                  application: application, contexts: []))
                updateApplicationTriggers(data)
              }
            }, label: {
              Text(application.displayName)
            })
          }
        } label: {
          Text("Add Application")
        }
        .environment(\.buttonGrayscaleEffect, !data.isEmpty)
        .environment(\.buttonHoverEffect, !data.isEmpty)
      }
      .environment(\.menuCalm, false)
      .environment(\.menuUnfocusedOpacity, 0.5)
      .frame(minHeight: 44)

      if !data.isEmpty {
        let count = data.count
        let itemHeight: CGFloat = 60

        ScrollView {
          LazyVStack {
            ForEach($data, id: \.id) { element in
              ApplicationTriggerItem(element, data: $data, selectionManager: selectionManager)
                .contentShape(Rectangle())
                .dropDestination(DetailViewModel.ApplicationTrigger.self, color: .accentColor, onDrop: { _, _ in
                  let ids = Array(selectionManager.selections)
                  guard let (from, destination) = data.moveOffsets(for: element.wrappedValue, with: ids) else {
                    return false
                  }

                  withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                    data.move(fromOffsets: IndexSet(from), toOffset: destination)
                  }
                  updateApplicationTriggers(data)
                  return false
                })
                .focusable(focus, as: .detail(.applicationTrigger(element.id))) {
                  selectionManager.handleOnTap(data, element: element.wrappedValue)
                }
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
              updateApplicationTriggers(data)
            }
          }
          .onChange(of: data, perform: { newValue in
            updateApplicationTriggers(newValue)
          })
          .focused(focus, equals: .detail(.applicationTriggers))
        }
        .scrollDisabled(count <= 3)
        .frame(minHeight: itemHeight - 2, maxHeight: maxHeight(count, itemHeight: itemHeight))
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

  private func maxHeight(_ count: Int, itemHeight: CGFloat) -> CGFloat {
    let result: CGFloat = if count > 1 {
      min(CGFloat(count) * itemHeight, 300)
    } else {
      itemHeight
    }
    return result
  }
}

extension DetailViewModel.ApplicationTrigger.Context {
  var appTriggerContext: ApplicationTrigger.Context {
    switch self {
    case .launched: .launched
    case .closed: .closed
    case .frontMost: .frontMost
    case .resignFrontMost: .resignFrontMost
    }
  }
}

#Preview {
  @FocusState var focus: AppFocus?
  return WorkflowApplicationTrigger(
    $focus,
    data: [
      .init(id: "1", name: "Finder", application: .finder(), contexts: []),
      .init(id: "2", name: "Calendar", application: .calendar(), contexts: []),
    ],
    selectionManager: SelectionManager(),
    onTab: {},
  )
  .environmentObject(ApplicationStore.shared)
  .padding()
}
