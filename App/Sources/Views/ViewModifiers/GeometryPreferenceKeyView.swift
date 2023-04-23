import SwiftUI

struct GeometryPreferenceKeyView<Key: PreferenceKey>: ViewModifier {
    typealias Transform = (GeometryProxy) -> Key.Value
    private let space: CoordinateSpace
    private let transform: Transform

    init(space: CoordinateSpace, transform: @escaping Transform) {
        self.space = space
        self.transform = transform
    }

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { Color.clear.preference(key: Key.self, value: transform($0)) })
    }
}

