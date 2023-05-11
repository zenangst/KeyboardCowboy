import Foundation
import UniformTypeIdentifiers
import SwiftUI

final class WorkflowCommandDropUrlDelegate: DropDelegate {
  var uttypes: [UTType] = [.fileURL, .url, .text]
  var destination: Int?

  private let onDrop: ([URL]) -> Void
  @State var isValid: Bool = false
  @Binding var isVisible: Bool
  @Binding var urls: Set<URL>

  init(isVisible: Binding<Bool>,
       urls: Binding<Set<URL>>,
       onDrop: @escaping ([URL]) -> Void) {
    _isVisible = isVisible
    _urls = urls
    self.onDrop = onDrop
  }

  func dropExited(info: DropInfo) {
    isVisible = false
    urls.removeAll()
  }

  func dropEntered(info: DropInfo) { }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    let itemProviders = info.itemProviders(for: uttypes)
    let validation = itemProviders.allSatisfy { itemProvider in
      itemProvider.canLoadObject(ofClass: URL.self)
    }

    isValid = validation
    isVisible = validation

    return isValid ? DropProposal(operation: .copy) : nil
  }

  func validateDrop(info: DropInfo) -> Bool {
    var result = false

    for itemProvider in info.itemProviders(for: uttypes) {
      if itemProvider.canLoadObject(ofClass: URL.self) {
        result = true
        _ = itemProvider.loadObject(ofClass: URL.self) { url, error in
          guard let url else { return }
          self.urls.insert(url)
        }
      }
    }

    return result
  }

  func performDrop(info: DropInfo) -> Bool {
    onDrop(Array(urls))
    urls.removeAll()
    return true
  }
}
