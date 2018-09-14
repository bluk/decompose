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

@testable import DecomposeCore
import XCTest

// swiftlint:disable type_body_length
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

    func testHexadecimalSuccess() {
        let hexadecimal: Parser<StringInput, [Character]> = Combinators.Text.hexadecimal().many()
        let input = StringInput("1234567890ABCDEF")

        let result = hexadecimal.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B", "C", "D", "E", "F"])
        XCTAssertEqual(remainingInput.position, 16)
    }

    func testHexadecimalFailure() {
        let hexadecimal: Parser<StringInput, Character> = Combinators.Text.hexadecimal()
        let input = StringInput("G")

        let result = hexadecimal.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([
            Symbol<Character>.value("1"),
            Symbol<Character>.value("2"),
            Symbol<Character>.value("3"),
            Symbol<Character>.value("4"),
            Symbol<Character>.value("5"),
            Symbol<Character>.value("6"),
            Symbol<Character>.value("7"),
            Symbol<Character>.value("8"),
            Symbol<Character>.value("9"),
            Symbol<Character>.value("0"),
            Symbol<Character>.value("A"),
            Symbol<Character>.value("B"),
            Symbol<Character>.value("C"),
            Symbol<Character>.value("D"),
            Symbol<Character>.value("E"),
            Symbol<Character>.value("F")
        ]))
    }

    func testHexadecimalAsIntSuccess() {
        let hexadecimalAsInt: Parser<StringInput, Int> = Combinators.Text.hexadecimalAsInt()
        let input = StringInput("B")

        let result = hexadecimalAsInt.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 11)
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testHexadecimalAsIntFailure() {
        let hexadecimalAsInt: Parser<StringInput, Int> = Combinators.Text.hexadecimalAsInt()
        let input = StringInput("G")

        let result = hexadecimalAsInt.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([
            Symbol<Character>.value("1"),
            Symbol<Character>.value("2"),
            Symbol<Character>.value("3"),
            Symbol<Character>.value("4"),
            Symbol<Character>.value("5"),
            Symbol<Character>.value("6"),
            Symbol<Character>.value("7"),
            Symbol<Character>.value("8"),
            Symbol<Character>.value("9"),
            Symbol<Character>.value("0"),
            Symbol<Character>.value("A"),
            Symbol<Character>.value("B"),
            Symbol<Character>.value("C"),
            Symbol<Character>.value("D"),
            Symbol<Character>.value("E"),
            Symbol<Character>.value("F")
        ]))
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
        let stringParser: Parser<StringInput, Empty> = Combinators.Text.stringEmptyReturnValue("foo")
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
        let stringParser: Parser<StringInput, Empty> = Combinators.Text.stringEmptyReturnValue("foo")
        let input = StringInput("barfoo")

        let result = stringParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("f")]))
    }

    func testWhitespaceSuccessWithSpace() {
        let whitespaceParser: Parser<StringInput, Character> = Combinators.Text.whitespace()
        let input = StringInput(" ")

        let result = whitespaceParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, " ")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testWhitespaceSuccessWithTab() {
        let whitespaceParser: Parser<StringInput, Character> = Combinators.Text.whitespace()
        let input = StringInput("\t")

        let result = whitespaceParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "\t")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testWhitespaceFailure() {
        let whitespaceParser: Parser<StringInput, Character> = Combinators.Text.whitespace()
        let input = StringInput("\n")

        let result = whitespaceParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "whitespace", { _ in true })]))
    }

    func testNewlineSuccessWithCarriageReturn() {
        let newlineParser: Parser<StringInput, Character> = Combinators.Text.newline()
        let input = StringInput("\n")

        let result = newlineParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "\n")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testNewlineSuccessWithLinefeed() {
        let newlineParser: Parser<StringInput, Character> = Combinators.Text.newline()
        let input = StringInput("\r")

        let result = newlineParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "\r")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testNewlineFailure() {
        let newlineParser: Parser<StringInput, Character> = Combinators.Text.newline()
        let input = StringInput("\t")

        let result = newlineParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "newline", { _ in true })]))
    }

    func testTabSuccess() {
        let tabParser: Parser<StringInput, Character> = Combinators.Text.tab()
        let input = StringInput("\t")

        let result = tabParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "\t")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testTabFailure() {
        let tabParser: Parser<StringInput, Character> = Combinators.Text.tab()
        let input = StringInput("    ")

        let result = tabParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("\t")]))
    }

    static var allTests = [
        ("testIsLetterSuccess", testIsLetterSuccess),
        ("testIsLetterFailure", testIsLetterFailure),
        ("testIsDigitSuccess", testIsDigitSuccess),
        ("testIsDigitFailure", testIsDigitFailure),
        ("testHexadecimalSuccess", testHexadecimalSuccess),
        ("testHexadecimalFailure", testHexadecimalFailure),
        ("testHexadecimalAsIntSuccess", testHexadecimalAsIntSuccess),
        ("testHexadecimalAsIntFailure", testHexadecimalAsIntFailure),
        ("testStringSuccess", testStringSuccess),
        ("testStringFailure", testStringFailure),
        ("testStringEmptyReturnValueSuccess", testStringEmptyReturnValueSuccess),
        ("testStringEmptyReturnValueFailure", testStringEmptyReturnValueFailure),
        ("testWhitespaceSuccessWithSpace", testWhitespaceSuccessWithSpace),
        ("testWhitespaceSuccessWithTab", testWhitespaceSuccessWithTab),
        ("testWhitespaceFailure", testWhitespaceFailure),
        ("testNewlineSuccessWithCarriageReturn", testNewlineSuccessWithCarriageReturn),
        ("testNewlineSuccessWithLinefeed", testNewlineSuccessWithLinefeed),
        ("testNewlineFailure", testNewlineFailure),
        ("testTabSuccess", testTabSuccess),
        ("testTabFailure", testTabFailure)
    ]
}
// swiftlint:enable type_body_length
