import Bonzai
import Inject
import SwiftUI

struct ApplicationTriggerItem: View {
  @EnvironmentObject private var updater: ConfigurationUpdater
  @EnvironmentObject private var transaction: UpdateTransaction
  @ObserveInjection var inject
  @Binding var element: DetailViewModel.ApplicationTrigger
  @Binding private var data: [DetailViewModel.ApplicationTrigger]
  @State var isTargeted: Bool = false
  private let selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>

  init(_ element: Binding<DetailViewModel.ApplicationTrigger>,
       data: Binding<[DetailViewModel.ApplicationTrigger]>,
       selectionManager: SelectionManager<DetailViewModel.ApplicationTrigger>)
  {
    _element = element
    _data = data
    self.selectionManager = selectionManager
  }

  var body: some View {
    HStack(spacing: 8) {
      IconView(icon: element.icon, size: .init(width: 24, height: 24))
      VStack(alignment: .leading, spacing: 4) {
        Text(element.name)
          .font(.subheadline)
          .fontWeight(.bold)
          .frame(maxWidth: .infinity, alignment: .leading)
        ZenDivider()
        HStack {
          ForEach(DetailViewModel.ApplicationTrigger.Context.allCases) { context in
            Toggle(isOn: Binding<Bool>(get: {
              element.contexts.contains(context)
            }, set: { newValue in
              if newValue {
                element.contexts.append(context)
              } else {
                element.contexts.removeAll(where: { $0 == context })
              }
            }), label: {
              Text(context.displayValue)
            })
            .lineLimit(1)
            .allowsTightening(true)
            .truncationMode(.tail)
          }
          .environment(\.toggleStyle, .small)
          .environment(\.toggleFont, .caption)
        }
      }
      ZenDivider(.vertical)
      Button(
        action: {
          withAnimation(CommandList.animation) {
            if let index = data.firstIndex(of: element) {
              data.remove(at: index)
              updateApplicationTriggers(data)
            }
          }
        },
        label: {
          Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 8, height: 8)
        },
      )
      .buttonStyle(.destructive)
    }
    .contentShape(Rectangle())
    .roundedSubStyle(8, padding: 8)
    .overlay(BorderedOverlayView(.readonly { selectionManager.selections.contains(element.id) }, cornerRadius: 6))
    .draggable(element)
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
}
