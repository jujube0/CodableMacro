//
//  ExprSyntaxExtensions.swift
//  CodableMacro
//
//
import SwiftSyntax

extension ExprSyntax {
    var asSimpleString: String? {
        self.as(StringLiteralExprSyntax.self)?.segments.description
    }
}
