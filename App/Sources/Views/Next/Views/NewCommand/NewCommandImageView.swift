import SwiftUI

struct NewCommandImageView: View {
  @ObserveInjection var inject
  let kind: NewCommandView.Kind

  var body: some View {
    Group {
      switch kind {
      case .open:
        ZStack {
          Image(nsImage: NSWorkspace.shared.icon(forFile: "~/"))
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .rotationEffect(.degrees(5))
            .offset(.init(width: 4, height: -2))
          Image(nsImage: NSWorkspace.shared.icon(forFile: "~/".sanitizedPath))
            .resizable()
            .aspectRatio(1, contentMode: .fill)
        }
      case .url:
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"))
          .resizable()
          .aspectRatio(1, contentMode: .fit)
      case .application:
        Image(nsImage: NSWorkspace.shared.icon(forFile: "/Applications"))
          .resizable()
          .aspectRatio(1, contentMode: .fit)
      }
    }
    .frame(width: 24, height: 24)
    .enableInjection()
  }
}

