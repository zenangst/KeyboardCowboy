import Bonzai
import Inject
import SwiftUI

extension AnyTransition {
  static var moveAndFade: AnyTransition {
    .asymmetric(
      insertion:
          .scale(scale: 0.1, anchor: .trailing)
          .combined(with: .opacity)
      ,
      removal:
          .scale.combined(with: .opacity)
    )
  }
}

struct WorkflowNotificationMatchesView: View {
  @ObserveInjection var inject
  @ObservedObject var publisher: WorkflowNotificationPublisher

  var body: some View {
    let maxWorkflow = publisher.data.matches.max(by: { lhs, rhs in
      lhs.trigger.keyShortcutsCount < rhs.trigger.keyShortcutsCount
    })
    let columnCount = (maxWorkflow?.trigger.keyShortcutsCount ?? 0) + 1
    var gridItems: [GridItem] = [ ]
    let _ = Array(0..<columnCount - 1).forEach { offset in
      gridItems.append(GridItem(
        .flexible(minimum: 36, maximum: .infinity),
        spacing: 8,
        alignment: .trailing))
    }
    let _ = gridItems.append(GridItem(.fixed(26), alignment: .trailing))

    ScrollView {
      LazyVStack(spacing: 2) {
        ForEach(publisher.data.matches, id: \.id) { workflow in
          VStack(alignment: .leading, spacing: 0) {
            Text(workflow.name)
              .font(.caption)
              .bold()
              .shadow(color: .black, radius: 2)
              .padding(.horizontal, 4)
              .padding(.top, 4)
            ZenDivider(.horizontal)
              .padding(.vertical, 2)
            Grid(alignment: .trailing) {
              GridRow {
                switch workflow.trigger {
                case .keyboardShortcuts(let trigger):
                  ForEach(Array(zip(trigger.shortcuts.indices, trigger.shortcuts)), id: \.1) { offset, shortcut in
                    WorkflowNotificationKeyView(keyShortcut: shortcut, glow: .constant(false))
                      .roundedContainer(4, padding: 1, margin: 1)
                      .opacity(offset == 0 ? 0.5 : 1)
                      .shadow(color: .accentColor.opacity(offset == 1 ? 1 : 0), radius: 3)
                  }
                case .application, .none, .snippet, .modifier:
                  Spacer()
                }
                padding(workflow, columnCount: columnCount - 1)
                Spacer()
                workflow.iconView(22)
                  .roundedContainer(8, padding: 0, margin: 1)
              }
            }
          }
        }
        .padding(8)
        .background(
          Color.clear
          .roundedContainer(8, padding: 2, margin: 1)
          .mask {
            LinearGradient(stops: [
              Gradient.Stop(color: .black.opacity(0.8), location: 0.0),
              Gradient.Stop(color: .black, location: 0.4),
            ], startPoint: .top, endPoint: .bottom)
            .padding(-8)
          }
        )
        .shadow(radius: 3)
      }
      .padding(4)
    }
    .frame(maxWidth: 300, maxHeight: .infinity)
    .scrollIndicators(.hidden)
    .opacity(publisher.data.matches.isEmpty ? 0 : 1)
    .enableInjection()
  }


  @ViewBuilder
  func padding(_ workflow: Workflow, columnCount: Int) -> some View {
    let count = (columnCount) - workflow.trigger.keyShortcutsCount
    let padding = (0..<count).map { Padding(id: "\($0)_\(workflow.id)") }
    ForEach(padding) { _ in
      Spacer()
    }
  }
}

struct WorkflowNotificationMatchesView_Previews: PreviewProvider {
  static let publisher: WorkflowNotificationPublisher = .init(
    .init(
      id: UUID().uuidString,
      workflow: Workflow(name: "Discord"),
      matches: [
      ],
      glow: false,
      keyboardShortcuts: [
        KeyShortcut(key: "d", modifiers: [.leftControl, .leftOption, .leftCommand]),
        KeyShortcut(key: "d")
      ]
    )
  )
  static var previews: some View {
    WorkflowNotificationMatchesView(publisher: publisher)
  }
}

private struct Padding: Hashable, Identifiable {
  let id: String
}

private extension Workflow.Trigger? {
  var keyShortcutsCount: Int {
    switch self {
    case .keyboardShortcuts(let keyboardShortcutTrigger):
       keyboardShortcutTrigger.shortcuts.count
    case .application, .snippet, .none, .modifier: 0
    }
  }
}
