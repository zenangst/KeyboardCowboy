import SwiftUI

protocol Toggleable: Identifiable, Equatable, CaseIterable {
  var id: String { get }
  var displayValue: String { get }
}

struct TogglesView<Data, ID>: View where Data: RandomAccessCollection,
                                         Data: MutableCollection,
                                         Data.Element: Toggleable,
                                         Data.Element: Hashable,
                                         ID: Hashable {
  @ObservedObject private var iO = Inject.observer
  @Binding private(set) var data: Data
  @Binding private(set) var enabled: Set<Data.Element>
  private(set) var id: KeyPath<Data.Element, ID>

  init(_ data: Data, enabled: Binding<Set<Data.Element>>, id: KeyPath<Data.Element, ID>) {
    _data = .constant(data)
    _enabled = enabled
    self.id = id
  }

  init(_ data: Binding<Data>, enabled: Binding<Set<Data.Element>>, id: KeyPath<Data.Element, ID>) {
    _data = data
    _enabled = enabled
    self.id = id
  }

  var body: some View {
    HStack {
      ForEach(data, id: id) { element in
        Toggle(element.displayValue, isOn: Binding<Bool>(get: {
          enabled.contains(element)
        }, set: { _ in
          if enabled.contains(element) {
            enabled.remove(element)
          } else {
            enabled.insert(element)
          }
        }))
        .lineLimit(1)
        .allowsTightening(true)
        .id(element.id)
      }
    }.enableInjection()
  }
}

struct TogglesView_Previews: PreviewProvider {
  enum Toggle: String, Toggleable, CaseIterable, Hashable {
    var id: String { rawValue }
    var displayValue: String { rawValue.capitalized }
    case radio, toggle, checkbox
  }
  static var previews: some View {
    TogglesView(.constant(Toggle.allCases),
                enabled: .constant([.checkbox]),
                id: \.id)
      .padding()
  }
}
