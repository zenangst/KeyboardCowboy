import SwiftUI

enum AppMenuStyleEnum {
  case appStyle
}

struct AppMenuStyle: MenuStyle {
  func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .overlay(alignment: .trailing, content: {
        Image(systemName: "chevron.down")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundColor(Color.white.opacity(0.6))
          .frame(width: 12)
          .padding(.trailing, 6)
          .allowsHitTesting(false)
      })
      .padding(4)
      .background(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color(.white).opacity(0.2), lineWidth: 1)
      )
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
  }
}

extension View {
  @ViewBuilder
  func menuStyle(_ style: AppMenuStyleEnum) -> some View {
    switch style {
    case .appStyle:
      self.menuStyle(AppMenuStyle())
    }
  }
}
