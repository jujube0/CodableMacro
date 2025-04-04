//
//  NestedInMacro.swift
//  CodableMacro
//
//  Created by lauren.c on 4/3/25.
//
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

struct NestedInMacro: ValidatedPeerMacro {
    static let attrName = "NestedIn"
    static let supportedAttachedKinds: [DeclarationKind] = [.variable]
    
    static func validateAndExpand(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
