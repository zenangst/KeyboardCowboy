import Apps
import Bonzai
import Inject
import SwiftUI

struct WorkflowApplicationTriggerView: View {
  enum Action {
    case updateApplicationTriggers([DetailViewModel.ApplicationTrigger])
    case updateApplicationTriggerContext(DetailViewModel.ApplicationTrigger)
  }

  @ObserveInjection var inject
  @EnvironmentObject private var applicationStore: ApplicationStore
  @ObservedObject private var selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  @State private var data: [DetailViewModel.ApplicationTrigger]
  @State private var selection: String = UUID().uuidString
  private let onAction: (Action) -> Void
  private var focus: FocusState<AppFocus?>.Binding
  private var onTab: () -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       data: [DetailViewModel.ApplicationTrigger],
       selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       onTab: @escaping () -> Void,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    _data = .init(initialValue: data)
    self.selectionManager = selectionManager
    self.onTab = onTab
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        GenericAppIconView(size: 28)
        Menu {
          ForEach(applicationStore.applications.lazy, id: \.path) { application in
            Button(action: {
              let uuid = UUID()
              withAnimation(WorkflowCommandListView.animation) {
                data.append(.init(id: uuid.uuidString, name: application.displayName,
                                  application: application, contexts: []))
              }
              onAction(.updateApplicationTriggers(data))
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
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach($data.lazy, id: \.id) { element in
              WorkflowApplicationTriggerItemView(element, data: $data,
                                                 selectionManager: selectionManager,
                                                 onAction: onAction)
              .contentShape(Rectangle())
              .dropDestination(DetailViewModel.ApplicationTrigger.self, color: .accentColor, onDrop: { items, location in

                let ids = Array(selectionManager.selections)
                guard let (from, destination) = data.moveOffsets(for: element.wrappedValue, with: ids) else {
                  return false
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
                  data.move(fromOffsets: IndexSet(from), toOffset: destination)
                }

                onAction(.updateApplicationTriggers(data))

                return false
              })
              .focusable(focus, as: .detail(.applicationTrigger(element.id))) {
                selectionManager.handleOnTap(data, element: element.wrappedValue)
              }
              ZenDivider()
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
          .focused(focus, equals: .detail(.applicationTriggers))
        }
        .scrollDisabled(data.count <= 4)
        .frame(minHeight: 48, maxHeight: min(CGFloat(data.count * 48), 300) )
        .roundedContainer(padding: 0, margin: 0)
      }
    }
    .enableInjection()
  }
}

struct WorkflowApplicationTriggerView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowApplicationTriggerView(
      $focus,
      data: [
        .init(id: "1", name: "Application 1", application: .finder(),
              contexts: []),
      ],
      selectionManager: SelectionManager(),
      onTab: { },
      onAction: { _ in }
    )
    .environmentObject(ApplicationStore.shared)
  }
}
