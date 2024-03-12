import Bonzai
import Inject
import SwiftUI

struct SidebarAddGroupButtonView: View {
  @ObserveInjection var inject
  @Binding private var isVisible: Bool
  private var namespace: Namespace.ID
  private var onAction: () -> Void

  init(isVisible: Binding<Bool>,
       namespace: Namespace.ID,
       onAction: @escaping () -> Void) {
    self._isVisible = isVisible
    self.namespace = namespace
    self.onAction = onAction
  }

  @ViewBuilder
  var body: some View {
    Button(action: { onAction() }, label: {
      Image(systemName: "plus")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 8)
    })
    .buttonStyle(.zen(.init(calm: true, color: .systemGreen, grayscaleEffect: .constant(true))))
    .matchedGeometryEffect(id: "add-group-button", in: namespace)
    .help("Add Group")
    .opacity(isVisible ? 1 : 0)
  }
}

struct SidebarAddGroupButtonView_Previews: PreviewProvider {
  @Namespace static var namespace
  static var previews: some View {
    SidebarAddGroupButtonView(isVisible: .constant(true),
                              namespace: namespace,
                              onAction: { })
    .padding(40)
    .designTime()
  }
}
