import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import CodableMacroCore

let testMacros: [String: Macro.Type] = [
    "Codable": CodableMacro.self
]

final class CodableMacroTests: XCTestCase {
    
    func testEmptyStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Person {
            }
            """,
            expandedSource: """
            struct Person {
            }
            
            extension Person: Codable {
            }
            """,
            macros: testMacros
        )
    }
    
    func testSimpleStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Person {
                let id: Int
                var name: String
            }
            """,
            expandedSource: """
            struct Person {
                let id: Int
                var name: String
            
                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }
            
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(Int.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                }
            }
            
            extension Person: Codable {
            }
            """,
            macros: testMacros
        )
    }
    
    func testSimpleClass() throws {
        assertMacroExpansion(
            """
            @Codable
            class Person {
                let id: Int
                var name: String
            }
            """,
            expandedSource: """
            class Person {
                let id: Int
                var name: String
            
                init(id: Int, name: String) {
                    self.id = id
                    self.name = name
                }
            
                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                }
            
                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(Int.self, forKey: .id)
                    self.name = try container.decode(String.self, forKey: .name)
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                }
            }
            
            extension Person: Codable {
            }
            """,
            macros: testMacros
        )
        
        func testComputed() throws {
            assertMacroExpansion(
                """
                @Codable
                struct Person {
                    let id: Int
                    var name: String { "lauren" } 
                }
                """,
                expandedSource: """
                struct Person {
                    let id: Int
                    var name: String { "lauren" }
                
                    enum CodingKeys: String, CodingKey {
                        case id
                    }
                
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.id = try container.decode(Int.self, forKey: .id)
                    }
                
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(id, forKey: .id)
                    }
                }
                
                extension Person: Codable {
                }
                """,
                macros: testMacros
            )
        }
    }
    
    func testErrorIfEnum() throws {
        assertMacroExpansion(
            """
            @Codable
            enum Animal {
                case rabbit
            }
            """,
            expandedSource: """
            enum Animal {
                case rabbit
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "이 매크로는 class, struct에만 사용 가능합니다.", line: 1, column: 1),
                DiagnosticSpec(message: "이 매크로는 class, struct에만 사용 가능합니다.", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}
