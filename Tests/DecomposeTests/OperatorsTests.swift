//  Copyright 2018 Bryant Luk
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

@testable import Decompose
import XCTest

internal final class OperatorsTests: XCTestCase {

    func testChoiceSuccessAsOperator() {
        let matchesF: Parser<StringInput, Character> = Combinators.symbol("f")
        let matchesB: Parser<StringInput, Character> = Combinators.symbol("b")
        let choiceParser = matchesF <|> matchesB
        let input = StringInput("b")

        let result = choiceParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "b")
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testMapSuccessAsOperator() {
        let matches2: Parser<StringInput, Character> = Combinators.symbol("2")
        let mappedParser = { Int(String($0)) } <^> matches2

        let result = mappedParser.parse(StringInput("2"))
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 2)
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testApplySuccessAsOperator() {
        let symbol2: Parser<StringInput, Character> = Combinators.symbol("2")
        let symbol3: Parser<StringInput, Character> = Combinators.symbol("3")
        let symbolTimes: Parser<StringInput, Character> = Combinators.symbol("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
            Int(String(first))! * Int(String(second))!
            }
            }
        }
        let applyParser = func1 <^> symbol2 <*> symbolTimes <*> symbol3

        let result = applyParser.parse(StringInput("2*3"))
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 6)
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 3)
    }

    static var allTests = [
        ("testChoiceSuccessAsOperator", testChoiceSuccessAsOperator),
        ("testMapSuccessAsOperator", testMapSuccessAsOperator),
        ("testApplySuccessAsOperator", testApplySuccessAsOperator)
    ]
}
