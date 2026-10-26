import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import InjectionMacros

final class InjectableMacroTests: XCTestCase {
  private let macros: [String: Macro.Type] = ["Injectable": InjectableMacro.self]

  func testGeneratesObservationAndBody() {
    assertMacroExpansion(
      """
      @Injectable
      struct Example: View {
        var content: some View {
          Text("Hello")
          Text("World")
        }
      }
      """,
      expandedSource: """
      struct Example: View {
        @SwiftUI.ViewBuilder
        var content: some View {
          Text("Hello")
          Text("World")
        }

        @ObserveInjection private var _injectionObserver

        var body: some SwiftUI.View {
          content.enableInjection()
        }
      }
      """,
      macros: macros,
      indentationWidth: .spaces(2)
    )
  }

  func testPreservesExistingViewBuilderAndOtherMembers() {
    for attribute in ["ViewBuilder", "SwiftUI.ViewBuilder"] {
      assertMacroExpansion(
        """
        @Injectable
        struct Example: View {
          let title: String
          @\(attribute) var content: some View { Text(title) }
        }
        """,
        expandedSource: """
        struct Example: View {
          let title: String
          @\(attribute) var content: some View { Text(title) }

          @ObserveInjection private var _injectionObserver

          var body: some SwiftUI.View {
            content.enableInjection()
          }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(2)
      )
    }
  }

  func testRejectsExistingBody() {
    assertMacroExpansion(
      """
      @Injectable
      struct Example: View {
        var body: some View { Text("Hello") }
      }
      """,
      expandedSource: """
      struct Example: View {
        var body: some View { Text("Hello") }
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "@Injectable requires a content property instead of body",
          line: 1,
          column: 1
        ),
      ],
      macros: macros
    )
  }
}
