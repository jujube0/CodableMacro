//
//  PropertyInfoTests.swift
//  CodableMacro
//
//
import Testing
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

@testable import CodableMacroCore

@Suite("PropertyInfo 테스트")
final class PropertyInfoTests {
    
    private func parseVariableDecl(from source: String) throws -> VariableDeclSyntax {
        Parser.parse(source: source).statements.compactMap { statement in
            statement.item.as(VariableDeclSyntax.self)
        }.first!
    }
    
    @Test("let")
    func `let`() throws {
        let source = "let constantVar: String = \"Hello\""
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "constantVar")
        #expect(propertyInfo.type == .constant)
        #expect(propertyInfo.initializer?.description == "\"Hello\"")
        #expect(propertyInfo.dataType.description == "String")
        #expect(propertyInfo.attributes.isEmpty)
        #expect(!propertyInfo.isOptional)
        #expect(propertyInfo.wrappedDataType == "String")
    }
    
    @Test("optional var")
    func optionalVar() async throws {
        let source = "var optionalVar: String?"
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "optionalVar")
        #expect(propertyInfo.type == .variable)
        #expect(propertyInfo.initializer?.description == nil)
        #expect(propertyInfo.dataType.description == "String?")
        #expect(propertyInfo.attributes.isEmpty)
        #expect(propertyInfo.isOptional)
        #expect(propertyInfo.wrappedDataType == "String")
    }
    
    @Test("computed var with implicit get")
    func computedWithImplicitGet() async throws {
        let source = """
        var computedVar: Int {
            42
        }
        """
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "computedVar")
        #expect(propertyInfo.type == .computed)
        #expect(propertyInfo.initializer?.description == nil)
        #expect(propertyInfo.dataType.description == "Int")
        #expect(propertyInfo.attributes.isEmpty)
        #expect(!propertyInfo.isOptional)
        #expect(propertyInfo.wrappedDataType == "Int")
    }
    
    @Test("computed var with explicit get")
    func computedWithExplicitGet() async throws {
        let source = """
        var computedVar: Int {
            get { 42 }
        }
        """
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "computedVar")
        #expect(propertyInfo.type == .computed)
        #expect(propertyInfo.initializer?.description == nil)
        #expect(propertyInfo.dataType.description == "Int")
        #expect(propertyInfo.attributes.isEmpty)
        #expect(!propertyInfo.isOptional)
        #expect(propertyInfo.wrappedDataType == "Int")
    }
    
    @Test("computed var with explicit get and set")
    func computedWithGetAndSet() async throws {
        let source = """
        var computedVar: Int {
            get { 42 }
            set { newValue + 1 }
        }
        """
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "computedVar")
        #expect(propertyInfo.type == .computed)
        #expect(propertyInfo.initializer?.description == nil)
        #expect(propertyInfo.dataType.description == "Int")
        #expect(propertyInfo.attributes.isEmpty)
        #expect(!propertyInfo.isOptional)
    }
    
    @Test("attribute")
    func attribute() async throws {
        let source = """
        @Localized var attrVar: String
        """
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "attrVar")
        #expect(propertyInfo.type == .variable)
        #expect(propertyInfo.initializer?.description == nil)
        #expect(propertyInfo.dataType.description == "String")
        #expect(propertyInfo.attributes.count == 1)
        #expect(propertyInfo.attributes[0].name == "Localized")
        #expect(!propertyInfo.isOptional)
    }
    
    @Test("attributes")
    func attributes() async throws {
        let source = """
        @Localized()
        @Kitty("cat", owner: "me")
        var attrVar: String
        """
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "attrVar")
        #expect(propertyInfo.type == .variable)
        #expect(propertyInfo.initializer?.description == nil)
        #expect(propertyInfo.dataType.description == "String")
        #expect(propertyInfo.attributes.count == 2)
        
        #expect(propertyInfo.attributes[0].name == "Localized")
        #expect(propertyInfo.attributes[0].arguments.isEmpty)
        #expect(propertyInfo.attributes[1].name == "Kitty")
        
        #expect(propertyInfo.attributes[1].arguments.count == 2)
        #expect(propertyInfo.attributes[1].arguments[0].label == nil)
        #expect(propertyInfo.attributes[1].arguments[0].expression.description == "\"cat\"")
        
        #expect(propertyInfo.attributes[1].arguments[1].label == "owner")
        #expect(propertyInfo.attributes[1].arguments[1].expression.description == "\"me\"")
        
        #expect(!propertyInfo.isOptional)
    }
    
    @Test("type inference")
    func typeInference() async throws {
        let source = """
        var inferredVar = 123
        """
        let varDecl = try parseVariableDecl(from: source)
        
        #expect(throws: MacroError.self) {
            _ = try PropertyInfo.extract(from: varDecl)
        }
    }
    
    @Test("didSet")
    func didSet() throws {
        let source = """
        var observedVar: Int = 0 {
            didSet {
                print("Value changed")
            }
        }
        """
        let varDecl = try parseVariableDecl(from: source)
        
        let propertyInfo = try PropertyInfo.extract(from: varDecl)
        
        #expect(propertyInfo.name == "observedVar")
        #expect(propertyInfo.type == .variable)
        #expect(propertyInfo.initializer?.trimmedDescription == "0")
        #expect(propertyInfo.dataType.description == "Int")
        #expect(propertyInfo.attributes.count == 0)
        #expect(!propertyInfo.isOptional)
    }
    
    @Test("error: missing identifier")
    func missingIdentifierError() throws {
        let source = "var = 123"
        let varDecl = try parseVariableDecl(from: source)
        
        #expect(throws: MacroError.self) {
            try PropertyInfo.extract(from: varDecl)
        }
    }
}
