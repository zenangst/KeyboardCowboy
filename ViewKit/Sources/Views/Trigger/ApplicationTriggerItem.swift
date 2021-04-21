import SwiftUI
import ModelKit

struct ApplicationTriggerItem: View {
  @Binding var trigger: ApplicationTrigger

  var body: some View {
    HStack {
      IconView(path: trigger.application.path)
        .frame(width: 32, height: 32, alignment: .center)
      Text(trigger.application.displayName)
      Spacer()
      ForEach(ApplicationTrigger.Context.allCases) { context in
        Toggle(context.displayName,
               isOn: Binding<Bool>(
                get: { trigger.contexts.contains(context) == true },
                set: { _ in
                  if trigger.contexts.contains(context) {
                    trigger.contexts.remove(context)
                  } else {
                    trigger.contexts.insert(context)
                  }
                }
               )).font(.caption)
      }
    }
  }

  struct ApplicationTriggerItem_Previews: PreviewProvider {
    static var previews: some View {
      ApplicationTriggerItem(trigger: .constant(
        ApplicationTrigger(
          application: Application.finder(),
          contexts: [.frontMost])
      ))
    }
  }
}
