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
    case `static` // static 또는 class keyword로 정의된 경우
}

enum CustomAttribute: Hashable {
    
    case nested(_ path: [String])
    
    init?(_ syntaxInfo: AttributeSyntaxInfo) throws {
        
        switch syntaxInfo.name {
        case NestedInMacro.attrName:
            let pathExpr = syntaxInfo.arguments
                .filter { $0.label == nil }
            let paths = pathExpr.compactMap { $0.expression.as(StringLiteralExprSyntax.self)?.segments.description }
            self = .nested(paths)
        default:
            return nil
        }
    }
}

struct PropertyInfo {
    let name: String
    let type: PropertyType
    let initializer: ExprSyntax? // 변수의 초기값
    let dataType: TypeSyntax
    let attributes: [AttributeSyntaxInfo]
    let customAttributes: Set<CustomAttribute>
    
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
        guard let name = declaration.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            throw MacroError.message("변수 이름을 찾을 수 없습니다.")
        }
        
        guard let typeAnnotation = declaration.bindings.first?.typeAnnotation?.type.trimmed else {
            // let x = 3,
            // 또는 let x, y: String 등으로 정의된 경우 nil이 될 수 있음
            throw MacroError.message("타입을 명확하게 판단할 수 없습니다.")
        }
        
        let initializer = declaration.bindings.first?.initializer?.value
        
        let type: PropertyType
        
        let modifiers = declaration.modifiers
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class) }) {
            type = .static
        } else if declaration.bindingSpecifier.tokenKind == .keyword(.let) {
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
        
        let attributes: [AttributeSyntaxInfo] = declaration.attributes.compactMap {
            guard let attribute = $0.as(AttributeSyntax.self) else { return nil }
            return AttributeSyntaxInfo.extract(from: attribute)
        }
        
        let customAttributes: Set<CustomAttribute> = Set(try attributes.compactMap({ try CustomAttribute($0) }))
        
        return .init(
            name: name,
            type: type,
            initializer: initializer,
            dataType: typeAnnotation,
            attributes: attributes,
            customAttributes: customAttributes
        )
    }
    
//    func codingKeys() -> MemberBlockItemListSyntax {
//        
//    }
}
