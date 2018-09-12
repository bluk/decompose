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

internal final class CombinatorsTests: XCTestCase {

    func testPure() {
        let result = Combinators.pure("Hello, World!").computeParse(StringInput("A"), [Symbol.empty])

        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "Hello, World!")
        XCTAssertEqual(remainingInput.current(), "A")
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSymbolSuccess() {
        let symbolParser: Parser<StringInput, Character> = Combinators.symbol("H")

        let result = symbolParser.parse(StringInput("H"))
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "H")
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testSymbolFailure() {
        let symbolParser: Parser<StringInput, Character> = Combinators.symbol("H")

        let result = symbolParser.parse(StringInput("W"))
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("H")]))
    }

    func testSatisfySuccess() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy(conditionName: "f") { $0 == "f" }
        let input = StringInput("f")

        let result = matchesF.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "f")
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testSatisfyFailure() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy(conditionName: "f") { $0 == "f" }
        let input = StringInput("bar")

        let result = matchesF.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "f", { _ in true })]))
    }

    func testChoiceSuccess() {
        let matchesF: Parser<StringInput, Character> = Combinators.symbol("f")
        let matchesB: Parser<StringInput, Character> = Combinators.symbol("b")
        let choiceParser = Combinators.or(matchesF, matchesB)

        let result1 = choiceParser.parse(StringInput("f"))
        guard case let .success(remainingInput1, value1) = result1 else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value1, "f")
        XCTAssertNil(remainingInput1.current())
        XCTAssertEqual(remainingInput1.position, 1)

        let result2 = choiceParser.parse(StringInput("b"))
        guard case let .success(remainingInput2, value2) = result2 else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value2, "b")
        XCTAssertNil(remainingInput2.current())
        XCTAssertEqual(remainingInput2.position, 1)
    }

    func testChoiceFailure() {
        let matchesF: Parser<StringInput, Character> = Combinators.symbol("f")
        let matchesB: Parser<StringInput, Character> = Combinators.symbol("b")
        let choiceParser = Combinators.or(matchesF, matchesB)
        let input = StringInput("xyz")

        let result = choiceParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("f"), Symbol<Character>.value("b")]))
    }

    func testMapSuccess() {
        let matches2: Parser<StringInput, Character> = Combinators.symbol("2")
        let mappedParser = Combinators.map(matches2) { Int(String($0)) }

        let result = mappedParser.parse(StringInput("2"))
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 2)
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testMapFailure() {
        let matches2: Parser<StringInput, Character> = Combinators.symbol("2")
        let mappedParser = Combinators.map(matches2) { Int(String($0)) }

        let result = mappedParser.parse(StringInput("3"))
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("2")]))
    }

    func testApplySuccess() {
        let symbol2: Parser<StringInput, Character> = Combinators.symbol("2")
        let symbol3: Parser<StringInput, Character> = Combinators.symbol("3")
        let symbolTimes: Parser<StringInput, Character> = Combinators.symbol("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
                    Int(String(first))! * Int(String(second))!
                }
            }
        }
        let applyParser = Combinators.apply(Combinators.apply(Combinators.map(symbol2, func1), symbolTimes), symbol3)

        let result = applyParser.parse(StringInput("2*3"))
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 6)
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testApplyFailure() {
        let symbol2: Parser<StringInput, Character> = Combinators.symbol("2")
        let symbol3: Parser<StringInput, Character> = Combinators.symbol("3")
        let symbolTimes: Parser<StringInput, Character> = Combinators.symbol("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
                    Int(String(first))! * Int(String(second))!
                }
            }
        }
        let applyParser = Combinators.apply(Combinators.apply(Combinators.map(symbol2, func1), symbolTimes), symbol3)

        let result = applyParser.parse(StringInput("2+3"))
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 1)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("*")]))
    }

    func testFailSuccess() {
        let fail: Parser<StringInput, Character> = Combinators.fail()
        let input = StringInput("A")

        let result = fail.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol.empty]))
    }

    func testEndOfInputSuccess() {
        let endOfInput: Parser<StringInput, Decompose.Empty> = Combinators.endOfInput()
        let input = StringInput("")

        let result = endOfInput.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Empty.empty)
        XCTAssertNil(remainingInput.current())
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndOfInputFailure() {
        let endOfInput: Parser<StringInput, Decompose.Empty> = Combinators.endOfInput()
        let input = StringInput("A")

        let result = endOfInput.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol.empty]))
    }

    static var allTests = [
        ("testPure", testPure),
        ("testSymbolSuccess", testSymbolSuccess),
        ("testSymbolFailure", testSymbolFailure),
        ("testSatisfySuccess", testSatisfySuccess),
        ("testSatisfyFailure", testSatisfyFailure),
        ("testChoiceSuccess", testChoiceSuccess),
        ("testChoiceFailure", testChoiceFailure),
        ("testMapSuccess", testMapSuccess),
        ("testMapFailure", testMapFailure),
        ("testApplySuccess", testApplySuccess),
        ("testApplyFailure", testApplyFailure),
        ("testFailSuccess", testFailSuccess),
        ("testEndOfInputSuccess", testEndOfInputSuccess),
        ("testEndOfInputFailure", testEndOfInputFailure)
    ]
}
