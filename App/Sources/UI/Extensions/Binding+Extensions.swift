import SwiftUI

extension Binding {
    init(_ handler: @autoclosure @escaping () -> Value) {
        self.init(get: handler, set: { _ in })
    }

    static func readonly(_ value: @autoclosure @escaping () -> Value) -> Binding<Value> {
        Binding(value())
    }
}
