import SwiftUI

extension SidebarSplit {
  @Injectable
  struct ConfigurationsMenu: View {
    @State private var isPresented = false
    @State private var selection = "foo"

    var content: some View {
      VStack {
        Button {
          isPresented.toggle()
        } label: {
          HStack {
            Text(selection)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, \.large)
          .padding(.vertical, \.small)
          .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(.quaternary.opacity(0.35))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
          VStack(spacing: \.small) {
            configurationOption("bar")
            configurationOption("foo")
          }
          .padding()
          .frame(width: 220)
        }
      }
    }

    private func configurationOption(_ option: String) -> some View {
      Button {
        selection = option
        isPresented = false
      } label: {
        HStack {
          Text(option)
          Spacer()
          if selection == option {
            Image(systemName: "checkmark")
              .foregroundStyle(.secondary)
          }
        }
        .padding(.horizontal, \.large)
        .padding(.vertical, \.small)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
