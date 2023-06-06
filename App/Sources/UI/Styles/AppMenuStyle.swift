import SwiftUI

enum AppMenuStyleEnum {
  case appStyle(padding: Double)
}

struct AppMenuStyle: MenuStyle {
  private let padding: Double

  init(_ padding: Double) {
    self.padding = padding
  }

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
      .padding(padding)
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
    case .appStyle(let padding):
      self.menuStyle(AppMenuStyle(padding))
    }
  }
}
