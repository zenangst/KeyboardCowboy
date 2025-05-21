import Bonzai
import Cocoa
import SwiftUI

@MainActor
final class WallpaperSwitchPublisher: ObservableObject {
  @Published var transaction: WallpaperSwitchView.Transaction

  init(_ transaction: WallpaperSwitchView.Transaction) {
    self.transaction = transaction
  }
}

struct WallpaperSwitchView: View {
  struct Transaction {
    let screen: NSScreen
    let currentWallpaper: URL?
    let nextWallpaper: URL
    var state: State

    init(from currentWallpaper: URL?, to nextWallpaper: URL, on screen: NSScreen) {
      self.currentWallpaper = currentWallpaper
      self.nextWallpaper = nextWallpaper
      self.state = .notSet
      self.screen = screen
    }
  }
  enum State: Equatable {
    case notSet
    case initialized
    case set
  }

  @ObservedObject var publisher: WallpaperSwitchPublisher

  var body: some View {
    ZStack {
      image(at: publisher.transaction.currentWallpaper)
        .blur(radius: publisher.transaction.state == .initialized ? 50 : 0)
        .offset(y: publisher.transaction.state == .initialized ? 10 : 0)
      image(at: publisher.transaction.nextWallpaper)
        .offset(y: publisher.transaction.state == .initialized ? 0 : -10)
        .opacity(publisher.transaction.state == .initialized ? 1 : 0)
        .blur(radius: publisher.transaction.state == .initialized ? 0 : 100)
    }
  }

  @ViewBuilder
  func image(at url: URL?) -> some View {
    if let url, let data = try? Data(contentsOf: url),
       let nsImage = NSImage(data: data) {
      Image(nsImage: nsImage)
        .resizable()
        .aspectRatio(
          publisher.transaction.screen.frame.size.width / publisher.transaction.screen.frame.size.height,
          contentMode: .fill)
    }
  }
}

#Preview {
  let currentWallpaper = NSWorkspace.shared.desktopImageURL(for: NSScreen.main!)
  let nextWallpaper = "~/Library/Mobile Documents/com~apple~CloudDocs/Desktop Pictures/Pixel/iefk8v9bwqhe1.png"
  let path = (nextWallpaper as NSString).expandingTildeInPath
  let nextWallpaperUrl = URL(fileURLWithPath: path)
  let publisher = WallpaperSwitchPublisher(
    .init(from: currentWallpaper,
          to: nextWallpaperUrl,
          on: NSScreen.main!)
  )

  return WallpaperSwitchView(publisher: publisher)
    .onAppear {
      withAnimation(.linear(duration: 2.0).delay(1.0)) {
        publisher.transaction.state = .initialized
      }
//
//      withAnimation(.linear(duration: 1.0).delay(3)) {
//        publisher.state = .set
//      }
    }
}
