import CodableMacro

struct Person {
    static let x = "hello"
    let id: Int
    var name: String?
}

extension Person: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
    }
}

Person(id: 2)
