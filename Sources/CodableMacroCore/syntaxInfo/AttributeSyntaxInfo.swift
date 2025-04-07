//
//  AttributeSyntaxInfo.swift
//  CodableMacro
//
//
import SwiftSyntax

struct AttributeSyntaxInfo {
    let name: String
    let arguments: [ArgumentSyntaxInfo]
    
    static func extract(from attribute: AttributeSyntax) -> Self? {
        guard let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
            return nil
        }
        
        var arguments: [ArgumentSyntaxInfo] = []
        if let argumentList = attribute.arguments?.as(LabeledExprListSyntax.self) {
            arguments = argumentList.map {
                ArgumentSyntaxInfo.extract(from: $0)
            }
        }
        
        return .init(name: name, arguments: arguments)
    }
}
