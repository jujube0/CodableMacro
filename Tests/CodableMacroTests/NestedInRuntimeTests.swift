//
//  NestedInRuntimeTests.swift
//  CodableMacro
//
//
import Testing
import Foundation
import CodableMacro

@Suite("@NestedIn 런타임테스트")
struct NestedInTests {
    @Codable
    struct SimpleStruct {
        let id: Int
        @NestedIn("info", "person")
        var name: String
        @NestedIn("info")
        var address: String?
        @NestedIn("privacy")
        let gender: String
        @NestedIn("favorites")
        var food: String?
    }
    
    @Test
    func simple() async throws {
        let json = """
                {
                  "id": 100,
                  "info": {
                    "person": {
                      "name": "김민수"
                    },
                    "address": "서울시 강남구 테헤란로"
                  },
                  "privacy": {
                    "gender": "남성"
                  },
                  "favorites": {
                     "food": "banana"
                  }
                }
        """.data(using: .utf8)!
        
        let person = try JSONDecoder().decode(SimpleStruct.self, from: json)
        
        #expect(person.id == 100)
        #expect(person.name == "김민수")
        #expect(person.address == "서울시 강남구 테헤란로")
        #expect(person.gender == "남성")
        #expect(person.food == "banana")
        
        let encoded = try JSONEncoder().encode(person)
        let reDecoded = try JSONDecoder().decode(SimpleStruct.self, from: encoded)
        #expect(reDecoded.id == person.id)
        #expect(reDecoded.name == person.name)
        #expect(reDecoded.address == person.address)
        #expect(reDecoded.gender == person.gender)
        #expect(reDecoded.food == person.food)
    }
    
    @Test("optional이면서 container key가 존재하지 않는 경우 nil로 처리")
    func noContainerButOptional() async throws {
        let json = """
                    {
                      "id": 100,
                      "info": {
                        "person": {
                          "name": "김민수"
                        },
                        "address": "서울시 강남구 테헤란로"
                      },
                      "privacy": {
                        "gender": "남성"
                      }
                    }
        """.data(using: .utf8)!
        
        let person = try JSONDecoder().decode(SimpleStruct.self, from: json)
        
        #expect(person.id == 100)
        #expect(person.name == "김민수")
        #expect(person.address == "서울시 강남구 테헤란로")
        #expect(person.gender == "남성")
        #expect(person.food == nil)
    }
    
    @Test("optional이면서 key가 존재하지 않는 경우 nil로 처리")
    func noKeyButOptional() async throws {
        let json = """
                    {
                      "id": 100,
                      "info": {
                        "person": {
                          "name": "김민수"
                        },
                        "address": "서울시 강남구 테헤란로"
                      },
                      "privacy": {
                        "gender": "남성"
                      }, 
                      "favorites": {}
                    }
        """.data(using: .utf8)!
        
        let person = try JSONDecoder().decode(SimpleStruct.self, from: json)
        
        #expect(person.id == 100)
        #expect(person.name == "김민수")
        #expect(person.address == "서울시 강남구 테헤란로")
        #expect(person.gender == "남성")
        #expect(person.food == nil)
    }
    
    @Test("required면서 container key가 존재하지 않는 경우 에러")
    func noContainerAndRequired() async throws {
        let json = """
                {
                  "id": 100,
                  "info": {
                    "person": {
                      "name": "김민수"
                    },
                    "address": "서울시 강남구 테헤란로"
                  },
                  "favorites": {
                     "food": "banana"
                  }
                }
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            let _ = try JSONDecoder().decode(SimpleStruct.self, from: json)
        }
        
    }
    
    @Test("required면서 key가 존재하지 않는 경우 에러")
    func noKeyAndRequired() async throws {
        let json = """
                {
                  "id": 100,
                  "info": {
                    "person": {
                      "name": "김민수"
                    },
                    "address": "서울시 강남구 테헤란로"
                  },
                  "privacy": {},
                  "favorites": {
                     "food": "banana"
                  }
                }
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            let _ = try JSONDecoder().decode(SimpleStruct.self, from: json)
        }
    }
}
