import Bonzai
import SwiftUI

struct GroupDetailHeaderView: View {
  @EnvironmentObject var updater: ConfigurationUpdater
  @EnvironmentObject var transaction: UpdateTransaction
  @EnvironmentObject private var groupDetailPublisher: GroupDetailPublisher
  @EnvironmentObject private var groupPublisher: GroupPublisher
  @State var isEnabled: Bool = false

  var body: some View {
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

      ZenToggle(style: .medium, isOn: Binding<Bool>(get: { isEnabled }, set: { newValue in
        isEnabled = newValue
        updater.modifyGroup(using: transaction) { group in
          group.isDisabled = !newValue
        }
      }))
    }
    .padding(.bottom, 4)
    .padding(.horizontal, 14)
    .onChange(of: groupPublisher.data.isEnabled) { newValue in
      isEnabled = newValue
    }
    .onAppear {
      isEnabled = groupPublisher.data.isEnabled
    }

    ZenLabel("Workflows", style: .content)
      .padding(.leading, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
