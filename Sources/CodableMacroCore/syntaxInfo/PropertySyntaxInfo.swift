//
//  PropertySyntaxInfo.swift
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

struct PropertySyntaxInfo {
    let name: String
    let type: PropertyType
    let initializer: ExprSyntax? // 변수의 초기값
    let dataType: TypeSyntax
    let attributes: [AttributeSyntaxInfo]
    let customAttributes: CustomAttributes
    
    /// ?를 사용해서 정의됐는지만 체크한다
    var isOptional: Bool { dataType.is(OptionalTypeSyntax.self) }
    
    var wrappedDataType: String {
        if isOptional {
            return String(dataType.description.dropLast())
        } else {
            return dataType.description
        }
    }
    
    static func extract(from declaration: VariableDeclSyntax) throws -> PropertySyntaxInfo {
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
        
        return .init(
            name: name,
            type: type,
            initializer: initializer,
            dataType: typeAnnotation,
            attributes: attributes,
            customAttributes: CustomAttributes.extract(from: attributes)
        )
    }
    
    func codingKeys(_ usedKeys: inout Set<String>) throws -> MemberBlockItemListSyntax {
        var newKeys: [String] = []
        
        if !usedKeys.contains(name) {
            usedKeys.insert(name)
            newKeys.append(name)
        }
        
        customAttributes.codingPaths.forEach { path in
            if !usedKeys.contains(path) {
                usedKeys.insert(path)
                newKeys.append(path)
            }
        }
        
        return try MemberBlockItemListSyntax {
            for key in newKeys {
                try MemberBlockItemSyntax(caseName: key)
            }
        }
    }
    
    /// - Parameter usedKeys: 동일한 컨테이너를 중복해서 정의하지 않기 위해 다른 곳에서 이미 사용된 키들을 전달받음
    func decodeBlock(_ usedKeys: inout Set<String>) throws -> CodeBlockItemListSyntax {
        let decodeExpr = isOptional ? "decodeIfPresent" : "decode"
        
        guard !customAttributes.codingPaths.isEmpty else {
            return CodeBlockItemListSyntax {
                ExprSyntax("self.\(raw: name) = try container.\(raw: decodeExpr)(\(raw: wrappedDataType).self, forKey: .\(raw: name))")
            }
        }
        
        let (finalContainerName, expressions) = try customAttributes.codingPaths.reduce(
            ("container", expressions: [VariableDeclSyntax]())
        ) { result, codingPath in
            var (currentContainer, currentExpressions) = result
            let newContainerName = codingPath + "_" + currentContainer
            
            guard !usedKeys.contains(codingPath) else {
                return (newContainerName, currentExpressions)
            }
            usedKeys.insert(codingPath)
            
            let optionalWrapping = currentContainer == "container" ? "" : "?"
            let expr = try VariableDeclSyntax("let \(raw: newContainerName) = try? \(raw: currentContainer)\(raw: optionalWrapping).nestedContainer(keyedBy: CodingKeys.self, forKey: .\(raw: codingPath))")
            currentExpressions.append(expr)
            return (newContainerName, currentExpressions)
        }
        
        return try CodeBlockItemListSyntax {
            expressions
            if isOptional {
                ExprSyntax("self.\(raw: name) = try \(raw: finalContainerName)?.\(raw: decodeExpr)(\(raw: wrappedDataType).self, forKey: .\(raw: name))")
            } else {
                try IfExprSyntax("if let \(raw: finalContainerName)") {
                    ExprSyntax("self.\(raw: name) = try \(raw: finalContainerName).\(raw: decodeExpr)(\(raw: wrappedDataType).self, forKey: .\(raw: name))")
                } else: {
                    try VariableDeclSyntax("let context = DecodingError.Context(codingPath: [\(raw: customAttributes.codingPaths.map({ "CodingKeys.\($0)" }).joined(separator: ", "))], debugDescription: \"key not found\")")
                    ThrowStmtSyntax(expression: ExprSyntax("DecodingError.keyNotFound(CodingKeys.\(raw: name), context)"))
                }
            }
        }
    }
    
    /// - Parameter usedKeys: 동일한 컨테이너를 중복해서 정의하지 않기 위해 다른 곳에서 이미 사용된 키들을 전달받음
    func encodeBlock(_ usedKeys: inout Set<String>) throws -> CodeBlockItemListSyntax {
        let encodeExpr = isOptional ? "encodeIfPresent" : "encode"
        
        guard !customAttributes.codingPaths.isEmpty else {
            return CodeBlockItemListSyntax {
                ExprSyntax("try container.\(raw: encodeExpr)(self.\(raw: name), forKey: .\(raw: name))")
            }
        }
        
        let (finalContainerName, expressions) = try customAttributes.codingPaths.reduce(
            ("container", expressions: [VariableDeclSyntax]())
        ) { result, codingPath in
            var (currentContainer, currentExpressions) = result
            let newContainerName = codingPath + "_" + currentContainer
            
            guard !usedKeys.contains(codingPath) else {
                return (newContainerName, currentExpressions)
            }
            usedKeys.insert(codingPath)
            
            let expr = try VariableDeclSyntax("var \(raw: newContainerName) = \(raw: currentContainer).nestedContainer(keyedBy: CodingKeys.self, forKey: .\(raw: codingPath))")
            currentExpressions.append(expr)
            return (newContainerName, currentExpressions)
        }
        
        return CodeBlockItemListSyntax {
            expressions
            ExprSyntax("try \(raw: finalContainerName).\(raw: encodeExpr)(\(raw: name), forKey: .\(raw: name))")
        }
    }
}

struct CustomAttributes {
    var codingPaths: [String] = [] // NestedIn(_ path: )
    
    static func extract(from attributes: [AttributeSyntaxInfo]) -> Self {
        var result = CustomAttributes()
        
        for attr in attributes {
            switch attr.name {
            case NestedInMacro.name:
                let paths = attr.arguments.filter { $0.label == nil }
                    .compactMap { $0.expression.asSimpleString }
                result.codingPaths = paths
            default:
                continue
            }
        }
        
        return result
    }
}
