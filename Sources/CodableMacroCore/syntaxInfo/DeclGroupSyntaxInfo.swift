//
//  DeclGroupSyntaxInfo.swift
//  CodableMacro
//
//
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

package enum DeclarationKind {
    case `struct`
    case `enum`
    case `class`
    case `protocol`
    case `variable`
    case `extension`
}

struct DeclGroupSyntaxInfo {
    let name: TokenSyntax
    let type: DeclarationKind
    let properties: [PropertyInfo]
    let modifiers: DeclModifierListSyntax
    let hasInitializer: Bool
    
    var isClass: Bool { type == .class }
    
    static func extract(from syntax: some DeclGroupSyntax) throws -> Self {
        let (name, type) = if let classDecl = syntax.as(ClassDeclSyntax.self) {
            (classDecl.name, .class)
        } else if let structDecl = syntax.as(StructDeclSyntax.self) {
            (structDecl.name, .struct)
        } else if let enumDecl = syntax.as(EnumDeclSyntax.self) {
            (enumDecl.name, .enum)
        } else {
            throw MacroError.message("매크로가 지원하지 않는 타입입니다.")
        } as (TokenSyntax, DeclarationKind)
        
        return .init(
            name: name,
            type: type,
            properties: try syntax.memberBlock.members
                .compactMap { $0.decl.as(VariableDeclSyntax.self) }
                .map(PropertyInfo.extract(from:)),
            modifiers: syntax.modifiers,
            hasInitializer: syntax.memberBlock.members
                .contains { $0.decl.is(InitializerDeclSyntax.self) }
        )
    }
}
