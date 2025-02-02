import Bonzai
import Inject
import SwiftUI

struct CommandListHeader: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject var publisher: CommandsPublisher
  private let namespace: Namespace.ID

  init(namespace: Namespace.ID) {
    self.namespace = namespace
  }

  var body: some View {
    HStack {
      ZenLabel("Commands")
      Spacer()
      Menu(content: {
        ForEach(DetailViewModel.Execution.allCases) { execution in
          Button(execution.rawValue, action: {
            updater.modifyWorkflow(using: transaction, withAnimation: .snappy(duration: 0.125)) { workflow in
              switch execution {
              case .concurrent: workflow.execution = .concurrent
              case .serial:     workflow.execution = .serial
              }
            }
          })
        }
      }, label: {
        Text(publisher.data.execution.rawValue)
          .font(.caption)
      })
      .fixedSize(horizontal: true, vertical: true)
      CommandListHeaderAddButton(namespace)
    }
    .menuStyle { menu in
      menu.padding = .medium
      menu.grayscaleEffect = true
      menu.cornerRadius = 6
    }
    .buttonStyle { button in
      button.grayscaleEffect = true
      button.backgroundColor = .systemGreen
      button.padding = .medium
      button.cornerRadius = 6
    }
  }
}

struct WorkflowCommandListHeaderView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    CommandListHeader(namespace: namespace)
      .designTime()
  }
}
