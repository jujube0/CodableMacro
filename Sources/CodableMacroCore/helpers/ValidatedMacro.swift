//
//  ValidatedMacro.swift
//  CodableMacro
//
//
import SwiftSyntax
import SwiftSyntaxMacros

enum DeclarationKind {
    case `struct`
    case `enum`
    case `class`
    case `protocol`
    case `variable`
    case `extension`
}

/// 매크로가 정의된 영역을 보고 적절하지 않은 경우 에러를 던진다.
/// 1. 정의되지 않은 타입에 추가된 경우
///
/// 매크로는 ``ValidatedMacro``를 직접 사용하는 대신
/// 이를 구현한 ValidatedMemberMacro, ValidatedExtensionMacro 등을 이용해야 한다.
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

protocol ValidatedExtensionMacro: ValidatedMacro, ExtensionMacro {
    static func validateAndExpand(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax]
}

protocol ValidatedAccessorMacro: ValidatedMacro, AccessorMacro {
    static func validateAndExpand(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax]
}

protocol ValidatedPeerMacro: ValidatedMacro, PeerMacro {
    static func validateAndExpand(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax]
}
