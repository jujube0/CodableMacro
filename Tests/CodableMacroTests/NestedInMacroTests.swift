import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class NestedInMacroTests: XCTestCase {
    func testSimpleStruct() throws {
        assertMacroExpansion(
            """
            @Codable
            struct Person {
                let name: String
            
                @NestedIn("privacy")
                let address: String?
            
                @NestedIn("privacy")
                let gender: String
            }
            """,
            expandedSource: """
            struct Person {
                let name: String
                let address: String?
                let gender: String

                init(name: String, address: String?, gender: String) {
                    self.name = name
                    self.address = address
                    self.gender = gender
                }

                enum CodingKeys: String, CodingKey {
                    case name
                    case address
                    case privacy
                    case gender
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    let privacy_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .privacy)
                    self.address = try privacy_container?.decodeIfPresent(String.self, forKey: .address)
                    if let privacy_container {
                        self.gender = try privacy_container.decode(String.self, forKey: .gender)
                    } else {
                        let context = DecodingError.Context(codingPath: [CodingKeys.privacy], debugDescription: "key not found")
                        throw DecodingError.keyNotFound(CodingKeys.gender, context)
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                    var privacy_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .privacy)
                    try privacy_container.encodeIfPresent(address, forKey: .address)
                    try privacy_container.encode(gender, forKey: .gender)
                }
            }

            extension Person: Codable {
            }
            """,
            macros: testMacros
        )
    }
}
