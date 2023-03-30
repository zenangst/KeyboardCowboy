import SwiftUI

struct SystemCommandView: View {
  let kind: SystemCommand.Kind

  var body: some View {
    Text(kind.displayValue)
  }
}

struct SystemCommandView_Previews: PreviewProvider {
  static var previews: some View {
    SystemCommandView(kind: .missionControl)
  }
}
