# CodableMacro
- [Custom Codable Macro #0 Macro란](https://velog.io/@jujube0/Custom-Codable-Macro-0-Macro란)
- [Custom Codable Macro #1 세팅](https://velog.io/@jujube0/Custom-Codable-Macro-1-세팅)
- [Custom Codable Macro #2 구현하기](https://velog.io/@jujube0/Custom-Codable-Macro-2-구현하기)

## requirements
iOS 15+/swift6.0

## usage

### @Codable
- struct 또는 class에 추가되는 attached macro
- Codable conformance를 자동으로 추가한다.
```swift
@Codable
struct Person {
    var name: String? 
    let age: Int
}
```

### @NestedIn(_ path: String...)
- nested 구조를 한번에 처리한다.
- 아래처럼 사용할 수 있다.
```swift
@Codable
struct Person {
    let name: String
    @NestedIn("privacy")
    var address: String
    @NestedIn("privacy")
    let gender: String
}

// 위 타입은 아래 json을 파싱한다.
{
    "name": "민수",
    "privacy": {
        "address": "서울시",
        "gender": "남성"
    }
}
```
<details>
<summary>추가되는 코드 (매크로를 우측 클릭한 후 expanded Macro를 선택해 확인 가능)</summary>

```swift
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
```
</details>

#### constraints
- `@Codable` 이 타입에 추가되어야 한다.
- `var` 이면서 `String?` 인 변수로 정의돼야 한다.

