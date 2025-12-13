import Bonzai
import HotSwiftUI
import SwiftUI

struct SidebarAddGroupButtonView: View {
  @ObserveInjection var inject
  @Binding private var isVisible: Bool
  private var namespace: Namespace.ID
  private var onAction: () -> Void

  init(isVisible: Binding<Bool>,
       namespace: Namespace.ID,
       onAction: @escaping () -> Void)
  {
    _isVisible = isVisible
    self.namespace = namespace
    self.onAction = onAction
  }

  @ViewBuilder
  var body: some View {
    if isVisible {
      Button(action: { onAction() }, label: {
        Text("Add Group")
          .font(.caption)
      })
      .matchedGeometryEffect(id: "add-group-button", in: namespace)
      .help("Add new Group")
    }
  }
}

struct SidebarAddGroupButtonView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    SidebarAddGroupButtonView(isVisible: .constant(true),
                              namespace: namespace,
                              onAction: {})
      .padding(40)
      .designTime()
  }
}
