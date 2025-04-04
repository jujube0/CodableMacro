//
//  ArgumentSyntaxInfo.swift
//  CodableMacro
//
//  Created by lauren.c on 4/3/25.
//
import SwiftSyntax

struct ArgumentSyntaxInfo {
    // _ 로 사용하는 경우 nil이다.
    let label: String?
    let expression: ExprSyntax
    
    static func extract(from labeledExpr: LabeledExprSyntax) -> Self {
        .init(label: labeledExpr.label?.text, expression: labeledExpr.expression)
    }
}

extension ExprSyntax {
    
}
