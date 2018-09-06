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

    func testReturnValue() {
        let output = Combinators.returnValue("Hello, World!").parse(StringInput("A"))

        guard case let .success(value, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "Hello, World!")
        XCTAssertEqual(remainder.peek(), "A")
        XCTAssertEqual(remainder.position, 0)
    }

    func testBind() {
        let originalParser: Parser<StringInput, String> = Combinators.returnValue("foo")
        let boundParser: Parser<StringInput, String> = Combinators.bind(originalParser) { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .success(value, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "bar")
        XCTAssertEqual(remainder, input)
    }

    func testBindWhereOriginalParserFails() {
        let originalParser: Parser<StringInput, String> = Parser {
            Consumed(.empty, .error(nil, $0.consume(count: 0)))
        }
        let boundParser: Parser<StringInput, String> = Combinators.bind(originalParser) { _ in
            XCTFail("Function should not be called")
            return Combinators.returnValue("unused")
        }
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .error(error, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption of characters")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
        XCTAssertEqual(remainder, input)
    }

    func testBindAsFlatMap() {
        let originalParser: Parser<StringInput, String> = Combinators.returnValue("foo")
        let boundParser: Parser<StringInput, String> = originalParser.flatMap { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .success(value, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "bar")
        XCTAssertEqual(remainder, input)
    }

    func testBindAsOperator() {
        let originalParser: Parser<StringInput, String> = Combinators.returnValue("foo")
        let func1: (String) -> Parser<StringInput, String> = { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let boundParser: Parser<StringInput, String> = originalParser >>- func1
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .success(value, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "bar")
        XCTAssertEqual(remainder, input)
    }

    func testSatisfy() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("foo")

        let output = matchesF.parse(input)
        guard case let .success(value, remainder) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `f`")
            return
        }
        XCTAssertEqual(value, "f")
        XCTAssertEqual(remainder.position, 1)
    }

    func testSatisfyWhenItDoesNotParse() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("bar")

        let output = matchesF.parse(input)
        guard case let .error(error, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
        XCTAssertEqual(remainder, input)
    }

    func testChoice() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = Combinators.choice(matchesF, matchesB)

        let output1 = orParser.parse(StringInput("foo"))
        guard case let .success(value1, remainder1) = output1.reply, .consumed == output1.state else {
            XCTFail("Expected parse to be successful and consumption of `f`")
            return
        }
        XCTAssertEqual(value1, "f")
        XCTAssertEqual(remainder1.position, 1)
        XCTAssertEqual(remainder1.peek(), "o")

        let output2 = orParser.parse(StringInput("bar"))
        guard case let .success(value2, remainder2) = output2.reply, .consumed == output2.state else {
            XCTFail("Expected parse to be successful and consumption of `b`")
            return
        }
        XCTAssertEqual(value2, "b")
        XCTAssertEqual(remainder2.position, 1)
        XCTAssertEqual(remainder2.peek(), "a")
    }

    func testChoiceWithNoMatch() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = Combinators.choice(matchesF, matchesB)
        let input = StringInput("xyz")

        let output = orParser.parse(input)
        guard case let .error(error, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
        XCTAssertEqual(remainder, input)
    }

    func testChoiceAsOperator() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = matchesF <|> matchesB
        let input = StringInput("bar")

        let output = orParser.parse(input)
        guard case let .success(value, remainder) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `b`")
            return
        }
        XCTAssertEqual(value, "b")
        XCTAssertEqual(remainder.position, 1)
        XCTAssertEqual(remainder.peek(), "a")
    }

    func testMap() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let mappedParser = Combinators.map(satisfy2) { Int(String($0)) }

        let output = mappedParser.parse(StringInput("2"))
        guard case let .success(value, _) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2`")
            return
        }
        XCTAssertEqual(value, 2)
    }

    func testMapWithNoMatch() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let mappedParser = Combinators.map(satisfy2) { Int(String($0)) }

        let output = mappedParser.parse(StringInput("3"))
        guard case let .error(error, _) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
    }

    func testMapAsOperator() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let func1: (Character) -> Int? = { Int(String($0)) }
        let mappedParser = satisfy2 <^> func1

        let output = mappedParser.parse(StringInput("2"))
        guard case let .success(value, _) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2`")
            return
        }
        XCTAssertEqual(value, 2)
    }

    func testApply() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let satisfy3: Parser<StringInput, Character> = Combinators.char("3")
        let satisfyTimes: Parser<StringInput, Character> = Combinators.char("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
                    Int(String(first))! * Int(String(second))!
                }
            }
        }
        let applyParser = Combinators.apply(Combinators.apply(Combinators.map(satisfy2, func1), satisfyTimes), satisfy3)

        let output = applyParser.parse(StringInput("2*3"))
        guard case let .success(value, _) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2*3`")
            return
        }
        XCTAssertEqual(value, 6)
    }

    func testApplyWithNoMatch() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let satisfy3: Parser<StringInput, Character> = Combinators.char("3")
        let satisfyTimes: Parser<StringInput, Character> = Combinators.char("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
                    Int(String(first))! * Int(String(second))!
                }
            }
        }
        let applyParser = Combinators.apply(Combinators.apply(Combinators.map(satisfy2, func1), satisfyTimes), satisfy3)

        let output = applyParser.parse(StringInput("2+3"))
        guard case let .error(error, _) = output.reply, .consumed == output.state  else {
            XCTFail("Expected parse to fail and consumption of `2`")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
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
        guard case let .success(value, _) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2*3`")
            return
        }
        XCTAssertEqual(value, 6)
    }

    static var allTests = [
        ("testReturnValue", testReturnValue),
        ("testBind", testBind),
        ("testBindWhereOriginalParserFails", testBindWhereOriginalParserFails),
        ("testBindAsOperator", testBindAsOperator),
        ("testSatisfy", testSatisfy),
        ("testSatisfyWhenItDoesNotParse", testSatisfyWhenItDoesNotParse),
        ("testChoice", testChoice),
        ("testChoiceWithNoMatch", testChoiceWithNoMatch),
        ("testChoiceAsOperator", testChoiceAsOperator),
        ("testMap", testMap),
        ("testMapWithNoMatch", testMapWithNoMatch),
        ("testMapAsOperator", testMapAsOperator),
        ("testApply", testApply),
        ("testApplyWithNoMatch", testApplyWithNoMatch),
        ("testApplyAsOperator", testApplyAsOperator)
    ]
}
