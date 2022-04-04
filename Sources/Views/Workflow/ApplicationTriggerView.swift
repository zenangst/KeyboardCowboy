import Apps
import SwiftUI

struct ApplicationTriggerView: View {
  @ObservedObject private var iO = Inject.observer
  @Binding var trigger: ApplicationTrigger

  var body: some View {
    HStack {
      IconView(path: trigger.application.path)
        .frame(width: 32, height: 32, alignment: .center)
      Text(trigger.application.displayName)
      Spacer()
      TogglesView(ApplicationTrigger.Context.allCases,
                  enabled: $trigger.contexts, id: \.id)
        .font(.caption)
    }
    .enableInjection()
  }

  struct ApplicationTriggerItem_Previews: PreviewProvider {
    static var previews: some View {
      ApplicationTriggerView(trigger: .constant(
        ApplicationTrigger(
          application: Application.finder(),
          contexts: [.frontMost])
      ))
    }
  }
}
