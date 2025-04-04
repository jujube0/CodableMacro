//
//  ValidatedMacroExtensions.swift
//  CodableMacro
//
//
import SwiftSyntax
import SwiftSyntaxMacros

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

extension ValidatedExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try SyntaxValidator.requireKind(declaration, supportedAttachedKinds)
        return try validateAndExpand(of: node, attachedTo: declaration, providingExtensionsOf: type, conformingTo: protocols, in: context)
    }
}

extension ValidatedAccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        try SyntaxValidator.requireKind(declaration, supportedAttachedKinds)
        return try validateAndExpand(of: node, providingAccessorsOf: declaration, in: context)
    }
}

extension ValidatedPeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try SyntaxValidator.requireKind(declaration, supportedAttachedKinds)
        return try validateAndExpand(of: node, providingPeersOf: declaration, in: context)
    }
}
