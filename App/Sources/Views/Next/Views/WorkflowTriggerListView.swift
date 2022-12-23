import SwiftUI

struct WorkflowTriggerListView: View {
  @State private var model: DetailViewModel
  private let onAction: (SingleDetailView.Action) -> Void

  init(_ model: DetailViewModel, onAction: @escaping (SingleDetailView.Action) -> Void) {
    _model = .init(initialValue: model)
    self.onAction = onAction
  }

  var body: some View {
    VStack(alignment: .leading) {
      WorkflowInfoView($model)
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
        .onChange(of: model) { model in
          onAction(.updateName(name: model.name, workflowId: model.id))
        }

      Group {
        switch model.trigger {
        case .keyboardShortcuts(let shortcuts):
          HStack {
            Button(action: {  },
                   label: { Image(systemName: "xmark") })
            .buttonStyle(KCButtonStyle())
            Label("Keyboard Shortcuts sequence:", image: "")
              .padding(.trailing, 12)
          }
          .padding([.leading, .trailing], 8)
          WorkflowShortcutsView(shortcuts)
          HStack {
            Spacer()
            Text("These keys need to be pressed in sequence in order to run the workflow.")
              .multilineTextAlignment(.center)
              .frame(alignment: .center)
              .font(.caption)
            Spacer()
          }
        case .applications(let triggers):
          HStack {
            Button(action: {  },
                   label: { Image(systemName: "xmark") })
            .buttonStyle(KCButtonStyle())
            Label("Application trigger:", image: "")
          }
          .padding([.leading, .trailing], 8)
          WorkflowApplicationTriggerView(triggers) { action in
            onAction(.applicationTrigger(action))
          }
          .padding(.bottom, 16)
        case .none:
          Label("Add a trigger:", image: "")
            .padding([.leading, .trailing], 8)
          WorkflowTriggerView(onAction: { action in
            onAction(.trigger(action))
          })

          HStack {
            Spacer()
            Text("Choose if you want to bind this workflow to an application or assign it a global keyboard shortcut sequence.")
              .multilineTextAlignment(.center)
              .frame(alignment: .center)
              .font(.caption)
            Spacer()
          }
        }
      }
    }
    .padding()
    .background(alignment: .bottom, content: {
      GeometryReader { proxy in
        Rectangle()
          .fill(Color(.textBackgroundColor))
        Path { path in
          path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height))
          path.addLine(to: CGPoint(x: proxy.size.width / 2 - 16, y: proxy.size.height))
          path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height + 8))
          path.addLine(to: CGPoint(x: proxy.size.width / 2 + 16, y: proxy.size.height))
        }
        .fill(Color(.textBackgroundColor))
      }
      .compositingGroup()
    })
    .shadow(radius: 4)
  }
}

struct WorkflowTriggerListView_Previews: PreviewProvider {
  static var previews: some View {
    WorkflowTriggerListView(DesignTime.detail) { _ in }
      .frame(height: 900)
  }
}
