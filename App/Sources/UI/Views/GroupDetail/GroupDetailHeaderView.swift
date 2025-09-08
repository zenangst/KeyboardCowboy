import Bonzai
import Inject
import SwiftUI

struct GroupDetailHeaderView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject private var groupDetailPublisher: GroupDetailPublisher
  @EnvironmentObject private var groupPublisher: GroupPublisher

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        GroupIconView(color: groupPublisher.data.color, icon: groupPublisher.data.icon, symbol: groupPublisher.data.symbol)
          .frame(width: 25, height: 25)
          .padding(4)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color(nsColor: .init(hex: groupPublisher.data.color)).opacity(0.4))
          )
        VStack(alignment: .leading) {
          Text(groupPublisher.data.name)
            .truncationMode(.middle)
            .allowsTightening(true)
            .lineLimit(1)
            .font(.headline)
          Text("Workflows: \(groupDetailPublisher.data.count)")
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Toggle(isOn: Binding<Bool>(get: { groupPublisher.data.isEnabled }, set: { newValue in
          groupPublisher.data.isDisabled = !newValue
          updater.modifyGroup(using: transaction) { group in
            group.isDisabled = !newValue
          }
        }), label: { })
          .switchStyle()
          .environment(\.switchForegroundColor, Color(hex: groupPublisher.data.color))
          .environment(\.switchBackgroundColor, Color(hex: groupPublisher.data.color))
          .id("group.toggle.\(groupPublisher.data.id)")
      }
    }
    .enableInjection()
  }
}
