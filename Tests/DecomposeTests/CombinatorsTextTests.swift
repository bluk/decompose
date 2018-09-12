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

internal final class CombinatorsTextTests: XCTestCase {

    func testIsLetterSuccess() {
        let letter: Parser<StringInput, Character> = Combinators.Text.letter()

        let result = letter.parse(StringInput("A"))
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "A")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testIsLetterFailure() {
        let letter: Parser<StringInput, Character> = Combinators.Text.letter()
        let input = StringInput("1")

        let result = letter.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "letter", { _ in true })]))
    }

    func testIsDigitSuccess() {
        let digit: Parser<StringInput, Character> = Combinators.Text.digit()
        let input = StringInput("1")

        let result = digit.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "1")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testIsDigitFailure() {
        let digit: Parser<StringInput, Character> = Combinators.Text.digit()
        let input = StringInput("A")

        let result = digit.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "digit", { _ in true })]))
    }

    func testStringSuccess() {
        let stringParser: Parser<StringInput, String> = Combinators.Text.string("foo")
        let input = StringInput("foo")

        let result = stringParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "foo")
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testStringFailure() {
        let stringParser: Parser<StringInput, String> = Combinators.Text.string("foo")
        let input = StringInput("bar")

        let result = stringParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("f")]))
    }

    func testStringEmptyReturnValueSuccess() {
        let stringParser: Parser<StringInput, Decompose.Empty> = Combinators.Text.stringEmptyReturnValue("foo")
        let input = StringInput("foo")

        let result = stringParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Empty.empty)
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testStringEmptyReturnValueFailure() {
        let stringParser: Parser<StringInput, Decompose.Empty> = Combinators.Text.stringEmptyReturnValue("foo")
        let input = StringInput("barfoo")

        let result = stringParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("f")]))
    }

    static var allTests = [
        ("testIsLetterSuccess", testIsLetterSuccess),
        ("testIsLetterFailure", testIsLetterFailure),
        ("testIsDigitSuccess", testIsDigitSuccess),
        ("testIsDigitFailure", testIsDigitFailure),
        ("testStringSuccess", testStringSuccess),
        ("testStringFailure", testStringFailure),
        ("testStringEmptyReturnValueSuccess", testStringEmptyReturnValueSuccess),
        ("testStringEmptyReturnValueFailure", testStringEmptyReturnValueFailure)
    ]
}
