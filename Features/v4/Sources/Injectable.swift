/// Generates injection observation and a SwiftUI `body` wrapping `content`.
/// Define `var content: some View`; the macro applies `@SwiftUI.ViewBuilder` automatically.
@attached(member, names: named(_injectionObserver), named(body))
@attached(memberAttribute)
macro Injectable() = #externalMacro(module: "InjectionMacros", type: "InjectableMacro")
