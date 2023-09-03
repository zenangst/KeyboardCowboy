import SwiftUI

struct AppMenuStyle: MenuStyle {
  private let config: AppButtonConfiguration
  private let fixedSize: Bool
  private let menuIndicator: Visibility
  @State private var isHovered: Bool

  init(_ config: AppButtonConfiguration,
       fixedSize: Bool = true,
       menuIndicator: Visibility = .visible) {
    self.config = config
    self.fixedSize = fixedSize
    self.menuIndicator = menuIndicator
    _isHovered = .init(initialValue: config.hoverEffect ? false : true)
  }

  func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .font(.caption)
      .truncationMode(.middle)
      .allowsTightening(true)
      .menuStyle(.borderlessButton)
      .menuIndicator(menuIndicator)
      .foregroundColor(Color(.textColor))
      .padding(.horizontal, config.padding.horizontal)
      .padding(.vertical, config.padding.vertical)
      .frame(minHeight: 24)
      .background(
        ZStack {
          RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            .fill(
              LinearGradient(stops: [
                .init(color: Color(config.nsColor), location: 0.0),
                .init(color: Color(config.nsColor.blended(withFraction: 0.3, of: .black)!), location: 0.025),
                .init(color: Color(config.nsColor.blended(withFraction: 0.5, of: .black)!), location: 1.0),
              ], startPoint: .top, endPoint: .bottom)
            )
            .opacity(isHovered ? 1.0 : 0.3)
          RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            .stroke(Color(nsColor: .shadowColor).opacity(0.2), lineWidth: 1)
            .offset(y: 0.25)
        }
      )
      .grayscale(config.grayscaleEffect ? isHovered ? 0 : 1 : 0)
      .compositingGroup()
      .shadow(color: Color.black.opacity(isHovered ? 0.5 : 0),
              radius: isHovered ? 1 : 1.25,
              y: isHovered ? 2 : 3)
      .opacity(isHovered ? 1.0 : 0.8)
      .animation(.easeOut(duration: 0.2), value: isHovered)
      .onHover(perform: { value in
        guard config.hoverEffect else { return }
        self.isHovered = value
      })
      .fixedSize(horizontal: fixedSize, vertical: true)
      .contentShape(Rectangle())
  }
}
