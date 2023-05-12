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
          ForEach(applicationStore.applications) { application in
            Button(action: {
              let uuid = UUID()
              withAnimation(WorkflowCommandListView.animation) {
                data.append(.init(id: uuid.uuidString, name: application.displayName,
                                  application: application, contexts: []))
              }
              onAction(.updateApplicationTriggers(data))
            }, label: {
              Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
              Text(application.displayName)
            })
          }
        } label: {
         Text("Add application")
        }
        .menuStyle(.appStyle(padding: 8))
      }

      LazyVStack(spacing: 4) {
        ForEach($data) { element in
          HStack(spacing: 0) {
            IconView(icon: element.wrappedValue.icon, size: .init(width: 36, height: 36))
            VStack(alignment: .leading, spacing: 4) {
              Text(element.name.wrappedValue)
              HStack {
                ForEach(DetailViewModel.ApplicationTrigger.Context.allCases) { context in
                  Toggle(context.displayValue, isOn: Binding<Bool>(get: {
                    element.contexts.wrappedValue.contains(context)
                  }, set: { newValue in
                    if newValue {
                      element.contexts.wrappedValue.append(context)
                    } else {
                      element.contexts.wrappedValue.removeAll(where: { $0 == context })
                    }

                    onAction(.updateApplicationTriggerContext(element.wrappedValue))
                  }))
                  .font(.caption)
                }
              }
            }
            .padding(8)
            Spacer()
            Divider()
              .opacity(0.25)
            Button(
              action: {
                withAnimation(WorkflowCommandListView.animation) {
                  if let index = data.firstIndex(of: element.wrappedValue) {
                    data.remove(at: index)
                  }
                }
                onAction(.updateApplicationTriggers(data))
              },
              label: {
                Image(systemName: "xmark")
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(width: 8, height: 8)
              })
            .buttonStyle(.gradientStyle(config: .init(nsColor: .systemRed, grayscaleEffect: true)))
            .padding(.horizontal, 8)
          }
          .padding(.leading, 8)
          .background(Color(.textBackgroundColor).opacity(0.75))
          .cornerRadius(8)
          .compositingGroup()
          .shadow(radius: 2)
          .onTapGesture {
            selectionManager.handleOnTap(data, element: element.wrappedValue)
            focusPublisher.publish(element.id)
          }
          .background(
            FocusView(focusPublisher, element: element, selectionManager: selectionManager,
                      cornerRadius: 8, style: .focusRing)
          )
          .draggable(element.draggablePayload(prefix: "WAT:", selections: selectionManager.selections))
          .dropDestination(for: String.self) { items, location in
            guard let payload = items.draggablePayload(prefix: "WAT:"),
                  let (from, destination) = data.moveOffsets(for: element.wrappedValue,
                                                             with: payload) else {
              return false
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)) {
              data.move(fromOffsets: IndexSet(from), toOffset: destination)
            }
            return true
          } isTargeted: { _ in }
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
    .debugEdit()
  }
}
