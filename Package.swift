// swift-tools-version: 5.9
// swift 5.9를 지원하기 위해 변경

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "CodableMacro",
    platforms: [.macOS(.v13), .iOS(.v15), .watchOS(.v6), .macCatalyst(.v13)], // *불필요한 platform 제외
    products: [
        .library(
            name: "CodableMacro",
            targets: ["CodableMacro"]
        ),
        // *executable은 제외해줬다. 이렇게 하면 package import 시 CodableMacroClient에 있는 main 파일은 실행할 수 없다.
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        .macro(
            name: "CodableMacroCore",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "CodableMacro", dependencies: ["CodableMacroCore"]),
        .executableTarget(name: "CodableMacroClient", dependencies: ["CodableMacro"]),
        .testTarget(
            name: "CodableMacroTests",
            dependencies: [
                "CodableMacroCore",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
