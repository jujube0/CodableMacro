
@attached(extension, conformances: Codable)
@attached(member, names: named(CodingKeys), named(encode(to:)), named(init))
public macro Codable() = #externalMacro(module: "CodableMacroCore", type: "CodableMacro")

@attached(peer)
public macro NestedIn() = #externalMacro(module: "CodableMacroCore", type: "NestedInMacro")
