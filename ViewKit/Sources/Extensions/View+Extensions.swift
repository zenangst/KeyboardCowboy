import BridgeKit
import SwiftUI

public extension View {
  func erase() -> AnyView {
    AnyView(self)
  }

  func cursorOnHover(_ cursor: NSCursor) -> some View {
    onHover(perform: { hovering in
      if hovering { cursor.push() } else { NSCursor.pop() }
    })
  }

  func onDrop(_ isTargeted: Binding<Bool>?, _ handler: @escaping ([URL]) -> Void) -> some View {
    onDrop(
      of: [.fileURL, .application, .text, .utf8PlainText],
      isTargeted: isTargeted,
      perform: { providers in
        var urls = Set<URL>()
        var counter = 0
        let completion = {
          counter -= 1
          if counter == 0 {
            DispatchQueue.main.async {
              handler(Array(urls))
            }
          }
        }

        for provider in providers {
          // Try and decode URL's
          if provider.canLoadObject(ofClass: URL.self) {
            counter += 1
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
              if let newUrl = url {
                urls.insert(newUrl)
              }
              completion()
            }
          }

          // Try and decode Strings
          if provider.canLoadObject(ofClass: String.self) {
            counter += 1
            _ = provider.loadObject(ofClass: String.self) { string, _ in
              if let string = string,
                 let url = URL(string: string) {
                urls.insert(url)
              }
              completion()
            }
          }
        }
        return true
      })
  }
}
