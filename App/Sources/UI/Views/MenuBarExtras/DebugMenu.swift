import SwiftUI

struct DebugMenu: View {
  @ObservedObject private var debugger = Debugger.shared

  var body: some View {
    Menu("Debug") {
      Button(action: {
        if debugger.enabledContexts.isEmpty {
          debugger.enabledContexts = Debugger.Context.allCases
        } else {
          debugger.enabledContexts = []
        }
      }, label: {
        Text("Toggle all")
      })
      Divider()
      ForEach(Debugger.Context.allCases, id: \.self) { context in
        Toggle(isOn: Binding(
          get: {
            debugger.enabledContexts.contains(context)
          },
          set: { isEnabled in
            if isEnabled {
              debugger.enabledContexts.append(context)
            } else {
              debugger.enabledContexts.removeAll(where: { $0 == context })
            }
          },
        )) {
          Text(context.displayValue)
        }
      }
    }
  }
}
