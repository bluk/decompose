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

    func testBindAsOperator() {
        let originalParser: Parser<StringInput, String> = Combinators.pure("foo")
        let func1: (String) -> Parser<StringInput, String> = { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.pure("bar")
        }
        let boundParser: Parser<StringInput, String> = originalParser >>- func1
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "bar")
        XCTAssertEqual(advancedInput, input)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testChoiceAsOperator() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = matchesF <|> matchesB
        let input = StringInput("bar")

        let output = orParser.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `b`")
            return
        }
        XCTAssertEqual(value, "b")
        XCTAssertEqual(advancedInput.position, 1)
        XCTAssertEqual(advancedInput.current(), "a")
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testMapAsOperator() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let func1: (Character) -> Int? = { Int(String($0)) }
        let mappedParser = satisfy2 <^> func1

        let output = mappedParser.parse(StringInput("2"))
        guard case let .success(value, _, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2`")
            return
        }
        XCTAssertEqual(value, 2)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 1)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testApplyAsOperator() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let satisfy3: Parser<StringInput, Character> = Combinators.char("3")
        let satisfyTimes: Parser<StringInput, Character> = Combinators.char("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
                    Int(String(first))! * Int(String(second))!
                }
            }
        }
        let applyParser = satisfy2 <^> func1 <*> satisfyTimes <*> satisfy3

        let output = applyParser.parse(StringInput("2*3"))
        guard case let .success(value, _, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2*3`")
            return
        }
        XCTAssertEqual(value, 6)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 3)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    static var allTests = [
        ("testBindAsOperator", testBindAsOperator),
        ("testChoiceAsOperator", testChoiceAsOperator),
        ("testMapAsOperator", testMapAsOperator),
        ("testApplyAsOperator", testApplyAsOperator)
    ]
}
