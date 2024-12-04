import Inject
import Bonzai
import SwiftUI

struct GroupDetailHeaderView: View {
  @ObserveInjection var inject
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject private var groupDetailPublisher: GroupDetailPublisher
  @EnvironmentObject private var groupPublisher: GroupPublisher

  var body: some View {
    VStack(spacing: 0) {
      ZenLabel("Group", style: .content)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
      HStack(spacing: 8) {
        GroupIconView(color: groupPublisher.data.color, icon: groupPublisher.data.icon, symbol: groupPublisher.data.symbol)
          .frame(width: 24, height: 24)
          .padding(4)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color(nsColor: .init(hex: groupPublisher.data.color)).opacity(0.4))
          )
        VStack(alignment: .leading) {
          Text(groupPublisher.data.name)
            .font(.headline)
          Text("Workflows: \(groupDetailPublisher.data.count)")
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        ZenToggle(config: .init(color: .custom(Color(.init(hex: groupPublisher.data.color)))),
                  style: .medium,
                  isOn: Binding<Bool>(get: { groupPublisher.data.isEnabled }, set: { newValue in
          groupPublisher.data.isDisabled = !newValue
          updater.modifyGroup(using: transaction) { group in
            group.isDisabled = !newValue
          }
        }))
        .id("group.toggle.\(groupPublisher.data.id)")
      }
      .padding(.bottom, 4)
      .padding(.horizontal, 14)
    }
    .enableInjection()
  }
}
