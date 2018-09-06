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

internal final class CombinatorsTest: XCTestCase {

    func testReturnValue() {
        guard let (result, remainder) = Combinators.returnValue("Hello, World!")
            .parse(StringInput("A")) else {
            XCTFail("Could not unwrap value")
            return
        }

        XCTAssertEqual(result, "Hello, World!")
        XCTAssertEqual(remainder.peek(), "A")
        XCTAssertEqual(remainder.position, 0)
    }

    func testBind() {
        let originalParser: Parser<StringInput, StringInput, String> = Combinators.returnValue("foo")
        let boundParser: Parser<StringInput, StringInput, String> = Combinators.bind(originalParser) { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let input = StringInput("test")
        guard let (result, remainder) = boundParser.parse(input) else {
            XCTFail("Could not unwrap value")
            return
        }

        XCTAssertEqual(result, "bar")
        XCTAssertEqual(remainder, input)
    }

    func testBindWhereOriginalParserFails() {
        let originalParser: Parser<StringInput, StringInput, String> = Parser { _ in nil }
        let boundParser: Parser<StringInput, StringInput, String> = Combinators.bind(originalParser) { _ in
            XCTFail("Function should not be called")
            return Combinators.returnValue("unused")
        }
        let input = StringInput("test")
        let output = boundParser.parse(input)

        XCTAssertNil(output)
    }

    func testBindAsFlatMap() {
        let originalParser: Parser<StringInput, StringInput, String> = Combinators.returnValue("foo")
        let boundParser: Parser<StringInput, StringInput, String> = originalParser.flatMap { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let input = StringInput("test")

        guard let (result, remainder) = boundParser.parse(input) else {
            XCTFail("Could not unwrap value")
            return
        }
        XCTAssertEqual(result, "bar")
        XCTAssertEqual(remainder, input)
    }

    func testBindAsOperator() {
        let originalParser: Parser<StringInput, StringInput, String> = Combinators.returnValue("foo")
        let func1: (String) -> Parser<StringInput, StringInput, String> = { result1 in
            XCTAssertEqual(result1, "foo")

            return Combinators.returnValue("bar")
        }
        let boundParser: Parser<StringInput, StringInput, String> = originalParser >>- func1
        let input = StringInput("test")

        guard let (result, remainder) = boundParser.parse(input) else {
            XCTFail("Could not unwrap value")
            return
        }
        XCTAssertEqual(result, "bar")
        XCTAssertEqual(remainder, input)
    }

    func testSatisfy() {
        let matchesF: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("foo")

        guard let (result, remainder) = matchesF.parse(input) else {
            XCTFail("Could not unwrap value")
            return
        }
        XCTAssertEqual(result, "f")

        XCTAssertEqual(remainder.position, 1)
    }

    func testSatisfyWhenItDoesNotParse() {
        let matchesF: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let input = StringInput("bar")

        let output = matchesF.parse(input)
        XCTAssertNil(output)
    }

    func testChoice() {
        let matchesF: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let matchesB: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "b" }
        let orParser = Combinators.choice(matchesF, matchesB)

        guard let (result1, remainder1) = orParser.parse(StringInput("foo")) else {
            XCTFail("Could not unwrap value")
            return
        }
        XCTAssertEqual(result1, "f")
        XCTAssertEqual(remainder1.position, 1)
        XCTAssertEqual(remainder1.peek(), "o")

        guard let (result2, remainder2) = orParser.parse(StringInput("bar")) else {
            XCTFail("Could not unwrap value")
            return
        }
        XCTAssertEqual(result2, "b")
        XCTAssertEqual(remainder2.position, 1)
        XCTAssertEqual(remainder2.peek(), "a")
    }

    func testChoiceWithNoMatch() {
        let matchesF: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let matchesB: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "b" }
        let orParser = Combinators.choice(matchesF, matchesB)

        let output = orParser.parse(StringInput("xyz"))
        XCTAssertNil(output)
    }

    func testChoiceAsOperator() {
        let matchesF: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "f" }
        let matchesB: Parser<StringInput, StringInput, Character> = Combinators.satisfy { $0 == "b" }
        let orParser = matchesF <|> matchesB

        let output = orParser.parse(StringInput("xyz"))
        XCTAssertNil(output)
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
        ("testChoiceAsOperator", testChoiceAsOperator)
    ]
}
