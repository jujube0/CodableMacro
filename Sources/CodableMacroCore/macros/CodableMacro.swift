//
//  CodableMacro.swift
//  CodableMacro
//
//
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

struct CodableMacro: ValidatedExtensionMacro, ValidatedMemberMacro {
    
    static let supportedAttachedKinds: [DeclarationKind] = [.class, .struct]
    
    static func validateAndExpand(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        [
            try ExtensionDeclSyntax("extension \(type): Codable { }")
        ]
    }
    
    // class 인 경우 required init(from:) 을 extension이 아닌, 타입 안에 넣어줘야 한다.
    static func validateAndExpand(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let declInfo = try DeclGroupSyntaxInfo.extract(from: declaration)
        
        let storedProperties = declInfo.properties.filter { $0.type != .computed }
        guard !storedProperties.isEmpty else { return [] }
        
        return [
            try generateInit(from: storedProperties),
            try generateCodingKeys(from: storedProperties),
            try generateDecodableInit(from: storedProperties, required: declInfo.isClass),
            try generateEncodeTo(from: storedProperties)
        ]
    }
}

private extension CodableMacro {
    
    /// - Parameter properties: 저장 프로퍼티
    static func generateInit(from properties: [PropertySyntaxInfo]) throws -> DeclSyntax {
        let argumentStr = properties.map { p in
            let defaultValueStr = p.initializer.flatMap { " = \($0)" } ?? ""
            return "\(p.name): \(p.dataType)\(defaultValueStr)"
        }.joined(separator: ", ")
        
        let decl = try InitializerDeclSyntax("init(\(raw: argumentStr))") {
            for p in properties {
                ExprSyntax("self.\(raw: p.name) = \(raw: p.name)")
            }
        }
        return DeclSyntax(decl)
    }
    
    /// - Parameter properties: 저장 프로퍼티
    static func generateCodingKeys(from properties: [PropertySyntaxInfo]) throws -> DeclSyntax {
        var usedKeys: Set<String> = []
        
        let decl = try EnumDeclSyntax("enum CodingKeys: String, CodingKey") {
            for p in properties {
                try p.codingKeys(&usedKeys)
            }
        }
        return DeclSyntax(decl)
    }
    
    /// - Parameter properties: 저장 프로퍼티
    /// - Parameter required: required keyword를 추가할지
    static func generateDecodableInit(from properties: [PropertySyntaxInfo], required: Bool) throws -> DeclSyntax {
        var usedKeys: Set<String> = []
        let decl = try InitializerDeclSyntax("\(raw: required ? "required " : "")init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.container(keyedBy: CodingKeys.self)")
            for p in properties {
                try p.decodeBlock(&usedKeys)
            }
        }
        return DeclSyntax(decl)
    }
    
    /// - Parameter properties: 저장 프로퍼티
    static func generateEncodeTo(from properties: [PropertySyntaxInfo]) throws -> DeclSyntax {
        var usedKeys: Set<String> = []
        let decl = try FunctionDeclSyntax("func encode(to encoder: Encoder) throws") {
            try VariableDeclSyntax("var container = encoder.container(keyedBy: CodingKeys.self)")
            for p in properties {
                try p.encodeBlock(&usedKeys)
            }
        }
        return DeclSyntax(decl)
    }
}

extension MemberBlockItemSyntax {
    init(caseName: String) throws {
        let caseStr = try EnumCaseDeclSyntax("case \(raw: caseName)")
        self.init(decl: caseStr)
    }
}
