import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

public struct InjectableMacro: MemberMacro, MemberAttributeMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingAttributesFor member: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    guard let property = member.as(VariableDeclSyntax.self),
          property.bindings.contains(where: {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "content"
          }) else {
      return []
    }
    let hasViewBuilder = property.attributes.contains { attribute in
      guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
      return ["ViewBuilder", "SwiftUI.ViewBuilder"].contains(attribute.attributeName.trimmedDescription)
    }
    return hasViewBuilder ? [] : ["@SwiftUI.ViewBuilder"]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) else {
      throw MacroExpansionErrorMessage("@Injectable requires a SwiftUI View struct")
    }
    let properties = declaration.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)
    }.flatMap { $0.bindings }.compactMap {
      $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }
    guard properties.contains("content"), !properties.contains("body") else {
      throw MacroExpansionErrorMessage(
        "@Injectable requires a content property instead of body"
      )
    }
    return [
      "@ObserveInjection private var _injectionObserver",
      """
      var body: some SwiftUI.View {
        content.enableInjection()
      }
      """,
    ]
  }
}

@main
struct InjectionPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [InjectableMacro.self]
}
