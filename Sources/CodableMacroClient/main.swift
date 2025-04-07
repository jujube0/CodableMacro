import Foundation
import CodableMacro

// 중첩된 JSON 구조를 처리하는 Person 구조체
@Codable
struct Person {
    let id: Int
    @NestedIn("info", "person")
    var name: String
    @NestedIn("info")
    var address: String?
    @NestedIn("privacy")
    var gender: String?
    
}
