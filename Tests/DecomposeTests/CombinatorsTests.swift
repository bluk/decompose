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

// swiftlint:disable type_body_length
internal final class CombinatorsTests: XCTestCase {

    func testReturnValue() {
        let output = Combinators.returnValue("Hello, World!").parse(StringInput("A"))

        guard case let .success(value, remainder, errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "Hello, World!")
        XCTAssertEqual(remainder.current(), "A")
        XCTAssertEqual(remainder.position, 0)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testBind() {
        let originalParser: Parser<StringInput, String> = Combinators.returnValue("foo")
        let boundParser: Parser<StringInput, String> = Combinators.bind(originalParser) { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "bar")
        XCTAssertEqual(remainder, input)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testBindWhereOriginalParserFails() {
        let originalParser: Parser<StringInput, String> = Parser { input in
            Consumed(.empty, .error({
                ParseError(position: input.position, unexpectedInput: "customInput", expectedProductions: [])
            }))
        }
        let boundParser: Parser<StringInput, String> = Combinators.bind(originalParser) { _ in
            XCTFail("Function should not be called")
            return Combinators.returnValue("unused")
        }
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption of characters")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "customInput")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testBindAsFlatMap() {
        let originalParser: Parser<StringInput, String> = Combinators.returnValue("foo")
        let boundParser: Parser<StringInput, String> = originalParser.flatMap { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "bar")
        XCTAssertEqual(remainder, input)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
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
        guard case let .success(value, remainder, errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "bar")
        XCTAssertEqual(remainder, input)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testSatisfy() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("foo")

        let output = matchesF.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `f`")
            return
        }
        XCTAssertEqual(value, "f")
        XCTAssertEqual(remainder.position, 1)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testSatisfyWhenItDoesNotParse() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("bar")

        let output = matchesF.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "b")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testChoice() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = Combinators.choice(matchesF, matchesB)

        let output1 = orParser.parse(StringInput("foo"))
        guard case let .success(value1, remainder1, errorGenerator1) = output1.reply, .consumed == output1.state else {
            XCTFail("Expected parse to be successful and consumption of `f`")
            return
        }
        XCTAssertEqual(value1, "f")
        XCTAssertEqual(remainder1.position, 1)
        XCTAssertEqual(remainder1.current(), "o")
        let error1 = errorGenerator1()
        XCTAssertEqual(error1.unexpectedInput, "")
        XCTAssertEqual(error1.position, 0)
        XCTAssertEqual(error1.expectedProductions, [])

        let output2 = orParser.parse(StringInput("bar"))
        guard case let .success(value2, remainder2, errorGenerator2) = output2.reply, .consumed == output2.state else {
            XCTFail("Expected parse to be successful and consumption of `b`")
            return
        }
        XCTAssertEqual(value2, "b")
        XCTAssertEqual(remainder2.position, 1)
        XCTAssertEqual(remainder2.current(), "a")
        let error2 = errorGenerator2()
        XCTAssertEqual(error2.unexpectedInput, "")
        XCTAssertEqual(error2.position, 0)
        XCTAssertEqual(error2.expectedProductions, [])
    }

    func testChoiceWithNoMatch() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = Combinators.choice(matchesF, matchesB)
        let input = StringInput("xyz")

        let output = orParser.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "x")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testChoiceAsOperator() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = matchesF <|> matchesB
        let input = StringInput("bar")

        let output = orParser.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `b`")
            return
        }
        XCTAssertEqual(value, "b")
        XCTAssertEqual(remainder.position, 1)
        XCTAssertEqual(remainder.current(), "a")
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testMap() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let mappedParser = Combinators.map(satisfy2) { Int(String($0)) }

        let output = mappedParser.parse(StringInput("2"))
        guard case let .success(value, _, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2`")
            return
        }
        XCTAssertEqual(value, 2)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testMapWithNoMatch() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let mappedParser = Combinators.map(satisfy2) { Int(String($0)) }

        let output = mappedParser.parse(StringInput("3"))
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "3")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testMapAsOperator() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let func1: (Character) -> Int? = { Int(String($0)) }
        let mappedParser = satisfy2 <^> func1

        let output = mappedParser.parse(StringInput("2"))
        guard case let .success(value, _, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2`")
            return
        }
        XCTAssertEqual(value, 2)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
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
        guard case let .success(value, _, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2*3`")
            return
        }
        XCTAssertEqual(value, 6)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 2)
        XCTAssertEqual(error.expectedProductions, [])
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
        guard case let .error(errorGenerator) = output.reply, .consumed == output.state  else {
            XCTFail("Expected parse to fail and consumption of `2`")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "+")
        XCTAssertEqual(error.position, 1)
        XCTAssertEqual(error.expectedProductions, [])
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
        guard case let .success(value, _, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2*3`")
            return
        }
        XCTAssertEqual(value, 6)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 2)
        XCTAssertEqual(error.expectedProductions, [])
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
// swiftlint:enable type_body_length
