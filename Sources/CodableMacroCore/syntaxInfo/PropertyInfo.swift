//
//  PropertyInfo.swift
//  CodableMacro
//
//
import SwiftSyntax

enum PropertyType {
    case constant
    case variable
    case computed
}

struct PropertyInfo {
    let name: String
    let type: PropertyType
    let initializer: ExprSyntax? // 변수의 초기값
    let dataType: TypeSyntax
    let attributes: [AttributeSyntaxInfo]
    
    /// ?를 사용해서 정의됐는지만 체크한다
    var isOptional: Bool { dataType.is(OptionalTypeSyntax.self) }
    
    var wrappedDataType: String {
        if isOptional {
            return String(dataType.description.dropLast())
        } else {
            return dataType.description
        }
    }
    
    static func extract(from declaration: VariableDeclSyntax) throws -> PropertyInfo {
        
        let attributes: [AttributeSyntaxInfo] = declaration.attributes.compactMap {
            guard let attribute = $0.as(AttributeSyntax.self) else { return nil }
            return AttributeSyntaxInfo.extract(from: attribute)
        }
        
        guard let name = declaration.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            throw MacroError.message("변수 이름을 찾을 수 없습니다.")
        }
        
        guard let typeAnnotation = declaration.bindings.first?.typeAnnotation?.type.trimmed else {
            // let x = 3 형식으로 정의된 경우 nil
            throw MacroError.message("타입 추론과 함께 사용할 수 없습니다.")
        }
        
        let initializer = declaration.bindings.first?.initializer?.value
        
        let type: PropertyType
        
        if declaration.bindingSpecifier.tokenKind == .keyword(.let) {
            type = .constant
        } else if initializer != nil {
            type = .variable
        } else if let accessors = declaration.bindings.first?.accessorBlock?.accessors {
            if let accessors = accessors.as(AccessorDeclListSyntax.self) {
                let isComputed = accessors.isEmpty || accessors.lazy
                    .map { $0.accessorSpecifier.tokenKind }
                    .contains { $0 == .keyword(.get) || $0 == .keyword(.set) }
                type = isComputed ? .computed : .variable
            } else {
                type = .computed
            }
        } else {
            type = .variable
        }
        
        return .init(
            name: name,
            type: type,
            initializer: initializer,
            dataType: typeAnnotation,
            attributes: attributes
        )
        
    }
}
