import SwiftCompilerPlugin // Swift 컴파일러와 연결되어 매크로 기능을 등록하고 실행할 수 있게 해준다.
import SwiftSyntax // 소스 코드를 Sytax Tree 구조로 표현해준다.
import SwiftSyntaxBuilder // Syntax Tree 구성을 위한 편리 API를 제공한다.
import SwiftSyntaxMacros // 매크로 작성에 필요한 프로토콜과 타입을 제공한다.

/// 매크로 기능을 Swift 컴파일러에 등록하는 진입점
/// @main은 이 구조체가 프로그램의 시작점임을 나타낸다.
///
/// CompilerPlugin을 채택하여:
/// 1. 컴파일러가 이 매크로 패키지를 플러그인으로 인식하게 하고
/// 2. providingMacros 배열을 통해 사용 가능한 매크로 목록을 컴파일러에 알린다.
///
/// 새로운 매크로를 추가하려면 providingMacros 배열에 해당 매크로 타입을 추가해야한다.
@main
struct CodableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableMacro.self,
    ]
}
