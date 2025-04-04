//
//  ValidatedMacro.swift
//  CodableMacro
//
//
import SwiftCompilerPlugin // Swift 컴파일러와 연결되어 매크로 기능을 등록하고 실행할 수 있게 해준다.
import SwiftSyntax // 소스 코드를 Sytax Tree 구조로 표현해준다.
import SwiftSyntaxMacros // 매크로 작성에 필요한 프로토콜과 타입을 제공한다.

protocol ValidatedMacro {
    static var supportedAttachedKinds: [DeclarationKind] { get }
}

protocol ValidatedMemberMacro: ValidatedMacro, MemberMacro {
    static func validateAndExpand(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax]
}

extension ValidatedMemberMacro {
    static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try SyntaxValidator.requireKind(declaration, supportedAttachedKinds)
        return try validateAndExpand(of: node, providingMembersOf: declaration, in: context)
    }
}

protocol ValidatedExtensionMacro: ValidatedMacro, ExtensionMacro {
    static func validateAndExpand(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax]
}

extension ValidatedExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try SyntaxValidator.requireKind(declaration, supportedAttachedKinds)
        return try validateAndExpand(of: node, attachedTo: declaration, providingExtensionsOf: type, conformingTo: protocols, in: context)
    }
}

protocol ValidatedPeerMacro: ValidatedMacro, PeerMacro {
    static func validateAndExpand(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax]
}

extension ValidatedPeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try SyntaxValidator.requireKind(declaration, supportedAttachedKinds)
        return try validateAndExpand(of: node, providingPeersOf: declaration, in: context)
    }
}
