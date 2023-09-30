import Apps
import SwiftUI

struct WorkflowApplicationTriggerView: View {
  enum Action {
    case updateApplicationTriggers([DetailViewModel.ApplicationTrigger])
    case updateApplicationTriggerContext(DetailViewModel.ApplicationTrigger)
  }

  @EnvironmentObject var applicationStore: ApplicationStore

  @State private var data: [DetailViewModel.ApplicationTrigger]
  @State private var selection: String = UUID().uuidString

  @ObservedObject private var selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>
  private var focusPublisher = FocusPublisher<DetailViewModel.ApplicationTrigger>()

  private var focus: FocusState<AppFocus?>.Binding
  private let onAction: (Action) -> Void

  init(_ focus: FocusState<AppFocus?>.Binding,
       data: [DetailViewModel.ApplicationTrigger],
       selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>,
       onAction: @escaping (Action) -> Void) {
    self.focus = focus
    self.selectionManager = selectionManager
    _data = .init(initialValue: data)
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Menu {
          ForEach(applicationStore.applications.lazy, id: \.id) { application in
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
         Text("Add application")
        }
        .menuStyle(
          AppMenuStyle(
            .init(
              nsColor: .systemGray,
              padding: .init(
                horizontal: 8,
                vertical: 8
              ),
              grayscaleEffect: false
            ),  fixedSize: false
          )
        )
      }

      LazyVStack(spacing: 4) {
        ForEach($data.lazy, id: \.id) { element in
          WorkflowApplicationTriggerItemView(element, data: $data,
                                             focusPublisher: focusPublisher,
                                             selectionManager: selectionManager,
                                             onAction: onAction)
          .onTapGesture {
            selectionManager.handleOnTap(data, element: element.wrappedValue)
            focusPublisher.publish(element.id)
          }
        }
        .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
          focus.wrappedValue = .detail(.commands)
        })
        .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
          selectionManager.selections = Set(data.map(\.id))
        })
        .onMoveCommand(perform: { direction in
          if let elementID = selectionManager.handle(direction, data, proxy: nil) {
            focusPublisher.publish(elementID)
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
      onAction: { _ in }
    )
    .environmentObject(ApplicationStore.shared)
  }
}
