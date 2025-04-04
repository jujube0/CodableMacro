//
//  DeclarationValidator.swift
//  CodableMacro
//
//
import SwiftCompilerPlugin // Swift 컴파일러와 연결되어 매크로 기능을 등록하고 실행할 수 있게 해준다.
import SwiftSyntax // 소스 코드를 Sytax Tree 구조로 표현해준다.
import SwiftSyntaxMacros // 매크로 작성에 필요한 프로토콜과 타입을 제공한다.

enum SyntaxValidator {
    
    static func requireKind(_ declaration: some DeclSyntaxProtocol, _ allowedKinds: [DeclarationKind]) throws {
        let isAllowed = allowedKinds.contains { kind in
            switch kind {
            case .struct:       return declaration.is(StructDeclSyntax.self)
            case .enum:         return declaration.is(EnumDeclSyntax.self)
            case .class:        return declaration.is(ClassDeclSyntax.self)
            case .protocol:     return declaration.is(ProtocolDeclSyntax.self)
            case .variable:     return declaration.is(VariableDeclSyntax.self)
            case .extension:    return declaration.is(ExtensionDeclSyntax.self)
            }
        }
        
        if !isAllowed {
            let allowedKindNames = allowedKinds.map { "\($0)" }.joined(separator: ", ")
            throw MacroError.message("이 매크로는 \(allowedKindNames)에만 사용 가능합니다.")
        }
    }
}
