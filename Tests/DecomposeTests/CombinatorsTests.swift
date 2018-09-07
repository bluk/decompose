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
        let output = Combinators.pure("Hello, World!").parse(StringInput("A"))

        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to be successful but no consumption of characters")
            return
        }
        XCTAssertEqual(value, "Hello, World!")
        XCTAssertEqual(advancedInput.current(), "A")
        XCTAssertEqual(advancedInput.position, 0)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testBind() {
        let originalParser: Parser<StringInput, String> = Combinators.pure("foo")
        let boundParser: Parser<StringInput, String> = Combinators.bind(originalParser) { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.pure("bar")
        }
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

    func testBindWhereOriginalParserFails() {
        let originalParser: Parser<StringInput, String> = Parser { input in
            Consumed(.empty, .error({
                ParseMessage(position: input.position, unexpectedInput: "customInput", expectedProductions: [])
            }))
        }
        let boundParser: Parser<StringInput, String> = Combinators.bind(originalParser) { _ in
            XCTFail("Function should not be called")
            return Combinators.pure("unused")
        }
        let input = StringInput("test")

        let output = boundParser.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption of characters")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "customInput")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testBindAsFlatMap() {
        let originalParser: Parser<StringInput, String> = Combinators.pure("foo")
        let boundParser: Parser<StringInput, String> = originalParser.flatMap { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.pure("bar")
        }
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

    func testSatisfy() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("foo")

        let output = matchesF.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `f`")
            return
        }
        XCTAssertEqual(value, "f")
        XCTAssertEqual(advancedInput.position, 1)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testSatisfyWhenItDoesNotParse() {
        let matchesF: Parser<StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("bar")

        let output = matchesF.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "b")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testChoice() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = Combinators.choice(matchesF, matchesB)

        let output1 = orParser.parse(StringInput("foo"))
        guard case let .success(value1, advancedInput1, msgGenerator1) = output1.reply,
            .consumed == output1.state else {
            XCTFail("Expected parse to be successful and consumption of `f`")
            return
        }
        XCTAssertEqual(value1, "f")
        XCTAssertEqual(advancedInput1.position, 1)
        XCTAssertEqual(advancedInput1.current(), "o")
        let msg1 = msgGenerator1()
        XCTAssertEqual(msg1.unexpectedInput, "")
        XCTAssertEqual(msg1.position, 0)
        XCTAssertEqual(msg1.expectedProductions, [])

        let output2 = orParser.parse(StringInput("bar"))
        guard case let .success(value2, advancedInput2, msgGenerator2) = output2.reply,
            .consumed == output2.state else {
            XCTFail("Expected parse to be successful and consumption of `b`")
            return
        }
        XCTAssertEqual(value2, "b")
        XCTAssertEqual(advancedInput2.position, 1)
        XCTAssertEqual(advancedInput2.current(), "a")
        let msg2 = msgGenerator2()
        XCTAssertEqual(msg2.unexpectedInput, "")
        XCTAssertEqual(msg2.position, 0)
        XCTAssertEqual(msg2.expectedProductions, [])
    }

    func testChoiceWithNoMatch() {
        let matchesF: Parser<StringInput, Character> = Combinators.char("f")
        let matchesB: Parser<StringInput, Character> = Combinators.char("b")
        let orParser = Combinators.choice(matchesF, matchesB)
        let input = StringInput("xyz")

        let output = orParser.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "x")
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

    func testMap() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let mappedParser = Combinators.map(satisfy2) { Int(String($0)) }

        let output = mappedParser.parse(StringInput("2"))
        guard case let .success(value, _, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2`")
            return
        }
        XCTAssertEqual(value, 2)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testMapWithNoMatch() {
        let satisfy2: Parser<StringInput, Character> = Combinators.char("2")
        let mappedParser = Combinators.map(satisfy2) { Int(String($0)) }

        let output = mappedParser.parse(StringInput("3"))
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail but no consumption of characters")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "3")
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
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
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
        guard case let .success(value, _, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `2*3`")
            return
        }
        XCTAssertEqual(value, 6)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 2)
        XCTAssertEqual(msg.expectedProductions, [])
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
        guard case let .error(msgGenerator) = output.reply, .consumed == output.state  else {
            XCTFail("Expected parse to fail and consumption of `2`")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "+")
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
        XCTAssertEqual(msg.position, 2)
        XCTAssertEqual(msg.expectedProductions, [])
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
