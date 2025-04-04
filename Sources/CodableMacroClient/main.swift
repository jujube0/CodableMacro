import CodableMacro

struct Person: Codable {
    static let x = "hello"
    let id: Int = 3
    var name: String?
}


