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
                let id: Int
                @NestedIn("info", "person")
                let name: String
            
                @NestedIn("info")
                let address: String?
            
                @NestedIn("privacy")
                let gender: String?
            }
            """,
            expandedSource: """
            struct Person {
                let id: Int
                let name: String
                let address: String?
                let gender: String?

                enum CodingKeys: String, CodingKey {
                    case id
                    case name
                    case info
                    case person
                    case address
                    case gender
                    case privacy
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.id = try container.decode(Int.self, forKey: .id)
                    let info_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .info)
                    let person_info_container = try? info_container?.nestedContainer(keyedBy: CodingKeys.self, forKey: .person)
                    if let person_info_container {
                        self.name = try person_info_container.decode(String.self, forKey: .name)
                    } else {
                        let context = DecodingError.Context(codingPath: [CodingKeys.info, CodingKeys.person], debugDescription: "key not found")
                        throw DecodingError.keyNotFound(CodingKeys.name, context)
                    }
                    self.address = try info_container?.decodeIfPresent(String.self, forKey: .address)
                    let privacy_container = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .privacy)
                    self.gender = try privacy_container?.decodeIfPresent(String.self, forKey: .gender)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(id, forKey: .id)
                    try container.encode(name, forKey: .name)
                    try container.encodeIfPresent(address, forKey: .address)
                    try container.encodeIfPresent(gender, forKey: .gender)
                }
            }

            extension Person: Codable {
            }
            """,
            macros: testMacros
        )
    }
}
