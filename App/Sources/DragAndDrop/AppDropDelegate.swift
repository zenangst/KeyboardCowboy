import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct AppDropDelegate<Element>: EditableDropDelegate where Element: Codable,
                                                            Element: Hashable {
  var uttypes: [String] = GenericDroplet<Element>.writableTypeIdentifiersForItemProvider

  private let onDrop: ([Element]) -> Void
  @State var isValid: Bool = false
  @Binding var isVisible: Bool
  @Binding var dropElements: Set<Element>

  init(isVisible: Binding<Bool>,
       dropElements: Binding<Set<Element>>,
       onDrop: @escaping ([Element]) -> Void) {
    _isVisible = isVisible
    _dropElements = dropElements
    self.onDrop = onDrop
  }

  func dropExited(info: DropInfo) {
    isVisible = false
    dropElements.removeAll()
  }

  func dropEntered(info: DropInfo) { }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    let isValid = !info.itemProviders(for: [UTType.data]).isEmpty
    isVisible = isValid

    return isValid ? DropProposal(operation: .copy) : nil
  }

  func validateDrop(info: DropInfo) -> Bool {
    let itemProviders = info.itemProviders(for: [UTType.data])
    isValid = !itemProviders.isEmpty

    for itemProvider in info.itemProviders(for: uttypes) {
      if itemProvider.canLoadObject(ofClass: GenericDroplet<Element>.self) {
        _ = itemProvider.loadObject(ofClass: GenericDroplet<Element>.self) { object, error in
          guard let droplet = object as? GenericDroplet<Element> else { return }
          dropElements = Set<Element>(droplet.models)
        }
      }
    }

    return isValid
  }

  func performDrop(info: DropInfo) -> Bool {
    onDrop(Array(dropElements))
    dropElements.removeAll()
    return true
  }
}
