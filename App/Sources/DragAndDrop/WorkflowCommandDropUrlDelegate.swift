import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct WorkflowCommandDropUrlDelegate: EditableDropDelegate {
  var uttypes: [String] = [UTType.fileURL.identifier]

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
    let isValid = !info.itemProviders(for: [UTType.fileURL]).isEmpty
    isVisible = isValid

    return isValid ? DropProposal(operation: .copy) : nil
  }

  func validateDrop(info: DropInfo) -> Bool {
    let itemProviders = info.itemProviders(for: [UTType.fileURL])
    isValid = !itemProviders.isEmpty

    for itemProvider in info.itemProviders(for: uttypes) {
      if itemProvider.canLoadObject(ofClass: URL.self) {
        _ = itemProvider.loadObject(ofClass: URL.self) { url, error in
          guard let url else { return }
          self.urls.insert(url)
        }
      }
    }

    return isValid
  }

  func performDrop(info: DropInfo) -> Bool {
    onDrop(Array(urls))
    urls.removeAll()
    return true
  }
}
