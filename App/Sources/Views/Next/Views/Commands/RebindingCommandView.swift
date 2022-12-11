import SwiftUI

struct RebindingCommandView: View {
  @ObserveInjection var inject
  @Binding var command: DetailViewModel.CommandViewModel

  var body: some View {
    if case .keyboard(let key, let modifiers) = command.kind {
      CommandContainerView(isEnabled: $command.isEnabled, icon: {
        HStack(spacing: 4) {
          ForEach(modifiers) { modifier in
            ModifierKeyIcon(key: modifier)
            .frame(width: 24, height: 24)
          }
          RegularKeyIcon(letter: key, width: 24, height: 24)
            .frame(width: 24, height: 24)
        }
      }, content: {
        Text(command.name)
      }, subContent: {

      }, onAction: {

      })
    } else {
      Text("Wrong kind")
    }
  }
}

struct RebindingCommandView_Previews: PreviewProvider {
  static var previews: some View {
    RebindingCommandView(command: .constant(DesignTime.rebindingCommand))
  }
}
