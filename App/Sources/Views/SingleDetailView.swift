import SwiftUI
import Apps

struct SingleDetailView: View {
  enum Action {
    case updateKeyboardShortcuts(workflowId: Workflow.ID, keyboardShortcuts: [KeyShortcut])
    case removeCommands(workflowId: Workflow.ID, commandIds: Set<Command.ID>)
    case applicationTrigger(workflowId: Workflow.ID, action: WorkflowApplicationTriggerView.Action)
    case commandView(workflowId: Workflow.ID, action: CommandView.Action)
    case moveCommand(workflowId: Workflow.ID, indexSet: IndexSet, toOffset: Int)
    case trigger(workflowId: Workflow.ID, action: WorkflowTriggerView.Action)
    case removeTrigger(workflowId: Workflow.ID)
    case setIsEnabled(workflowId: Workflow.ID, isEnabled: Bool)
    case updateName(workflowId: Workflow.ID, name: String)
    case dropUrls(workflowId: Workflow.ID, urls: [URL])
  }

  @Environment(\.openWindow) var openWindow
  @ObservedObject private var detailPublisher: DetailPublisher
  @State var overlayOpacity: CGFloat = 0
  private let onAction: (Action) -> Void

  init(_ detailPublisher: DetailPublisher, onAction: @escaping (Action) -> Void) {
    self.detailPublisher = detailPublisher
    self.onAction = onAction
  }

  var body: some View {
    ScrollViewReader { proxy in
        VStack(alignment: .leading) {
          WorkflowInfoView(detailPublisher, onAction: { action in
            switch action {
            case .updateName(let name):
              onAction(.updateName(workflowId: detailPublisher.model.id, name: name))
            case .setIsEnabled(let isEnabled):
              onAction(.setIsEnabled(workflowId: detailPublisher.model.id, isEnabled: isEnabled))
            }
          })
          .padding(.horizontal, 4)
          .padding(.vertical, 12)
          .id(detailPublisher.model.id)
          WorkflowTriggerListView(detailPublisher.model, onAction: onAction)
            .id(detailPublisher.model.id)
        }
        .padding([.top, .leading, .trailing])
        .padding(.bottom, 32)
        .background(alignment: .bottom, content: {
          Canvas(rendersAsynchronously: true) { context, size in
            context.fill(
              Path(CGRect(origin: .zero, size: CGSize(width: size.width,
                                                      height: size.height - 12))),
              with: .color(Color(.textBackgroundColor)))

            context.fill(Path { path in
              path.move(to: CGPoint(x: size.width / 2, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2 - 24, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 2))
              path.addLine(to: CGPoint(x: size.width / 2 + 24, y: size.height - 12))
              path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 12))
            }, with: .color(Color(.textBackgroundColor)))
          }
          .shadow(radius: 2, y: 2)
        })

      HStack {
        Label("Commands", image: "")
        Spacer()
        Group {
          Menu(content: {
            ForEach(DetailViewModel.Flow.allCases) {
              Button($0.rawValue, action: {})
            }
          }, label: {
            Text("Run \(detailPublisher.model.flow.rawValue)")
          }, primaryAction: {
          })
          .fixedSize()
        }
        .opacity(detailPublisher.model.commands.isEmpty ? 0 : 1)
        Button(action: {
          openWindow(value: NewCommandWindow.Context.newCommand(workflowId: detailPublisher.model.id))
        }) {
          HStack(spacing: 4) {
            Image(systemName: "plus")
          }
        }
        .padding(.horizontal, 4)
        .buttonStyle(.gradientStyle(config: .init(nsColor: .systemGreen, grayscaleEffect: true)))
      }
      .padding(.horizontal)
      .padding(.top, -6)

      ScrollView {
        WorkflowCommandListView(
          detailPublisher,
          scrollViewProxy: proxy,
          onAction: { action in
            onAction(action)
          })
        .onFrameChange(space: .named("WorkflowCommandListView"), perform: { rect in
          if rect.origin.y < 0 {
            overlayOpacity <- 1
          } else {
            overlayOpacity <- 0
          }
        })
      }
      .overlay(alignment: .top, content: { overlayView() })
      .coordinateSpace(name: "WorkflowCommandListView")
      .zIndex(2)
    }
    .labelStyle(HeaderLabelStyle())
  }

  private func overlayView() -> some View {
    VStack(spacing: 0) {
      LinearGradient(stops: [
        Gradient.Stop.init(color: .clear, location: 0),
        Gradient.Stop.init(color: .black.opacity(0.5), location: 0.1),
        Gradient.Stop.init(color: .black, location: 0.5),
        Gradient.Stop.init(color: .black.opacity(0.5), location: 0.9),
        Gradient.Stop.init(color: .clear, location: 1),
      ],
                     startPoint: .leading,
                     endPoint: .trailing)
      .frame(height: 1)
    }
      .opacity(overlayOpacity)
      .allowsHitTesting(false)
      .shadow(color: Color(.black).opacity(0.75), radius: 2, x: 0, y: 2)
      .animation(.default, value: overlayOpacity)
      .edgesIgnoringSafeArea(.top)
  }
}

struct SingleDetailView_Previews: PreviewProvider {
  static var previews: some View {
    SingleDetailView(.init(DesignTime.detail)) { _ in }
      .frame(height: 900)
  }
}
