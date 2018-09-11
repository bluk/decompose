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

// swiftlint:disable type_body_length file_length

internal final class ConvenienceCombinatorsTests: XCTestCase {

    func testIsLetterSuccess() {
        let letter: Parser<StringInput, Character> = Combinators.letter()

        let result = letter.parse(StringInput("A"))
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "A")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testIsLetterFailure() {
        let letter: Parser<StringInput, Character> = Combinators.letter()
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
        let digit: Parser<StringInput, Character> = Combinators.digit()
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
        let digit: Parser<StringInput, Character> = Combinators.digit()
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
        let stringParser: Parser<StringInput, String> = Combinators.string("foo")
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
        let stringParser: Parser<StringInput, String> = Combinators.string("foo")
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
        let stringParser: Parser<StringInput, Decompose.Empty> = Combinators.stringEmptyReturnValue("foo")
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
        let stringParser: Parser<StringInput, Decompose.Empty> = Combinators.stringEmptyReturnValue("foo")
        let input = StringInput("barfoo")

        let result = stringParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("f")]))
    }

    func testManySuccess() {
        let manyParser: Parser<StringInput, [Character]> = Combinators.many(Combinators.symbol("o"))
        let input = StringInput("ooo")

        let result = manyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["o", "o", "o"])
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testManySuccessWithEmptyInput() {
        let manyParser: Parser<StringInput, [Character]> = Combinators.many(Combinators.symbol("o"))
        let input = StringInput("")

        let result = manyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testManyFailure() {
        let manyParser: Parser<StringInput, [Character]> = Combinators.many(Combinators.symbol("o"))
        let input = StringInput("ooh")

        let result = manyParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 2)
        XCTAssertEqual(expectedSymbols, Set([Symbol.empty]))
    }

    func testMany1Success() {
        let many1Parser: Parser<StringInput, [Character]> = Combinators.many1(Combinators.symbol("o"))
        let input = StringInput("ooo")

        let result = many1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["o", "o", "o"])
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testMany1FailureWithEmptyInput() {
        let many1Parser: Parser<StringInput, [Character]> = Combinators.many1(Combinators.symbol("o"))
        let input = StringInput("")

        let result = many1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("o")]))
    }

    func testMany1SuccessComplex() {
        let many1Parser: Parser<StringInput, [String]> = Combinators.many1(Combinators.string("hello"))
        let input = StringInput("hellohello")

        let result = many1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["hello", "hello"])
        XCTAssertEqual(remainingInput.position, 10)
    }

    func testMany1Failure() {
        let many1Parser: Parser<StringInput, [Character]> = Combinators.many1(Combinators.symbol("o"))
        let input = StringInput("b")

        let result = many1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("o")]))
    }

    func testSkipManySuccess() {
        let skipManyParser: Parser<StringInput, Decompose.Empty> = Combinators.skipMany(Combinators.letter())
        let input = StringInput("foobar")

        let result = skipManyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Decompose.Empty.empty)
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testSkipManySuccessWithEmptyInput() {
        let skipManyParser: Parser<StringInput, Decompose.Empty> = Combinators.skipMany(Combinators.letter())
        let input = StringInput("")

        let result = skipManyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Decompose.Empty.empty)
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSkipManyFailure() {
        let skipManyParser: Parser<StringInput, Decompose.Empty> = Combinators.skipMany(Combinators.letter())
        let input = StringInput("123")

        let result = skipManyParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.empty]))
    }

    func testSkipMany1Success() {
        let skipMany1Parser: Parser<StringInput, Decompose.Empty> = Combinators.skipMany1(Combinators.letter())
        let input = StringInput("foobar")

        let result = skipMany1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Decompose.Empty.empty)
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testSkipMany1FailureWithEmptyInput() {
        let skipMany1Parser: Parser<StringInput, Decompose.Empty> = Combinators.skipMany1(Combinators.letter())
        let input = StringInput("")

        let result = skipMany1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "letter", { _ in true })]))
    }

    func testSkipMany1Failure() {
        let skipMany1Parser: Parser<StringInput, Decompose.Empty> = Combinators.skipMany1(Combinators.letter())
        let input = StringInput("123")

        let result = skipMany1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "letter", { _ in true })]))
    }

    func testOptionOptionalWithParserSuccess() {
        let optParser: Parser<StringInput, Character?> = Combinators.optionOptional(Combinators.letter())
        let input = StringInput("f")

        let result = optParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "f")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testOptionOptionalWithParserFailure() {
        let optParser: Parser<StringInput, Character?> = Combinators.optionOptional(Combinators.letter())
        let input = StringInput("")

        let result = optParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertNil(value)
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testOptionAndValueWithParserSuccess() {
        let optParser: Parser<StringInput, Character> = Combinators.option(Combinators.letter(), "A")
        let input = StringInput("f")

        let result = optParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "f")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testOptionAndValueWithParserFailure() {
        let optParser: Parser<StringInput, Character> = Combinators.option(Combinators.letter(), "A")
        let input = StringInput("")

        let result = optParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "A")
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testOptionalAndEmptyWithParserSuccess() {
        let optParser: Parser<StringInput, Empty> = Combinators.optional(Combinators.letter())
        let input = StringInput("f")

        let result = optParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Empty.empty)
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testOptionalAndEmptyWithParserFailure() {
        let optParser: Parser<StringInput, Empty> = Combinators.optional(Combinators.letter())
        let input = StringInput("")

        let result = optParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Empty.empty)
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testChainrSuccess() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainrParser: Parser<StringInput, Int> = Combinators.chainr(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("4-2-1")

        let result = chainrParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 4 - (2 - 1))
        XCTAssertEqual(remainingInput.position, 5)
    }

    func testChainrSuccessWithOneOperand() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainrParser: Parser<StringInput, Int> = Combinators.chainr(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("4")

        let result = chainrParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 4)
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testChainrSuccessWithEmptyInput() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainrParser: Parser<StringInput, Int> = Combinators.chainr(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("")

        let result = chainrParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Int.min)
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testChainrFailure() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainrParser: Parser<StringInput, Int> = Combinators.chainr(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("-4")

        let result = chainrParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "digit", { _ in true }), Symbol.empty]))
    }

    func testChainr1Success() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainr1Parser: Parser<StringInput, Int> = Combinators.chainr1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("4-2-1")

        let result = chainr1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 4 - (2 - 1))
        XCTAssertEqual(remainingInput.position, 5)
    }

    func testChainr1SuccessWithOnlyOperand() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainr1Parser: Parser<StringInput, Int> = Combinators.chainr1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("4")

        let result = chainr1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 4)
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testChainr1FailureWithEmptyInput() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainr1Parser: Parser<StringInput, Int> = Combinators.chainr1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("")

        let result = chainr1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "digit", { _ in true }), Symbol.empty]))
    }

    func testChainr1Failure() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainr1Parser: Parser<StringInput, Int> = Combinators.chainr1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("-2")

        let result = chainr1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "digit", { _ in true }), Symbol.empty]))
    }

    func testChainlSuccess() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value in { value2 in value2 - value } }
        }
        let chainlParser: Parser<StringInput, Int> = Combinators.chainl(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("4-2-1")

        let result = chainlParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, (4 - 2) - 1)
        XCTAssertEqual(remainingInput.position, 5)
    }

    func testChainlSuccessWithOneOperand() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainlParser: Parser<StringInput, Int> = Combinators.chainl(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("4")

        let result = chainlParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 4)
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testChainlSuccessWithEmptyInput() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainlParser: Parser<StringInput, Int> = Combinators.chainl(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("")

        let result = chainlParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Int.min)
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testChainlFailure() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainlParser: Parser<StringInput, Int> = Combinators.chainl(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-")),
            Int.min
        )
        let input = StringInput("-4")

        let result = chainlParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "digit", { _ in true }), Symbol.empty]))
    }

    func testChainl1Success() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainl1Parser: Parser<StringInput, Int> = Combinators.chainl1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("4-2-1")

        let result = chainl1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, (4 - 2) - 1)
        XCTAssertEqual(remainingInput.position, 5)
    }

    func testChainl1SuccessWithOnlyOperand() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainl1Parser: Parser<StringInput, Int> = Combinators.chainl1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("4")

        let result = chainl1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, 4)
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testChainl1FailureWithEmptyInput() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainl1Parser: Parser<StringInput, Int> = Combinators.chainl1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("")

        let result = chainl1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "digit", { _ in true }), Symbol.empty]))
    }

    func testChainl1Failure() {
        let intFunc: (Character) -> Int = { char in Int(String(char))! }
        let subtractFunc: (Character) -> (Int) -> (Int) -> Int = {
            _ in { value1 in { value2 in value2 - value1 } }
        }
        let chainl1Parser: Parser<StringInput, Int> = Combinators.chainl1(
            Combinators.apply(Combinators.pure(intFunc), Combinators.digit()),
            Combinators.apply(Combinators.pure(subtractFunc), Combinators.symbol("-"))
        )
        let input = StringInput("-2")

        let result = chainl1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "digit", { _ in true }), Symbol.empty]))
    }

    func testSepBySuccess() {
        let sepByParser: Parser<StringInput, [Character]> = Combinators.sepBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A2A3")

        let result = sepByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 5)
    }

    func testSepBySuccessWithOnlyValue() {
        let sepByParser: Parser<StringInput, [Character]> = Combinators.sepBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1")

        let result = sepByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testSepBySuccessWithEmptyInput() {
        let sepByParser: Parser<StringInput, [Character]> = Combinators.sepBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("")

        let result = sepByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepByFailureWithValueAndSeparator() {
        let sepByParser: Parser<StringInput, [Character]> = Combinators.sepBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A")

        let result = sepByParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testSepByFailureWithSeparator() {
        let sepByParser: Parser<StringInput, [Character]> = Combinators.sepBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("A")

        let result = sepByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepByFailure() {
        let sepByParser: Parser<StringInput, [Character]> = Combinators.sepBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("B")

        let result = sepByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepBy1Success() {
        let sepBy1Parser: Parser<StringInput, [Character]> = Combinators.sepBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A2A3")

        let result = sepBy1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 5)
    }

    func testSepBy1SuccessWithOnlyValue() {
        let sepBy1Parser: Parser<StringInput, [Character]> = Combinators.sepBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1")

        let result = sepBy1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testSepBy1FailureWithEmptyInput() {
        let sepBy1Parser: Parser<StringInput, [Character]> = Combinators.sepBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("")

        let result = sepBy1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepBy1FailureWithValueAndSeparator() {
        let sepBy1Parser: Parser<StringInput, [Character]> = Combinators.sepBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A")

        let result = sepBy1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testSepBy1FailureWithSeparator() {
        let sepBy1Parser: Parser<StringInput, [Character]> = Combinators.sepBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("A")

        let result = sepBy1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepBy1Failure() {
        let sepBy1Parser: Parser<StringInput, [Character]> = Combinators.sepBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("B")

        let result = sepBy1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testBetweenSuccess() {
        let betweenParser: Parser<StringInput, Character> = Combinators.between(
            Combinators.symbol("("),
            Combinators.digit(),
            Combinators.symbol(")")
        )
        let input = StringInput("(1)")

        let result = betweenParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "1")
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testBetweenFailureOnEmptyInput() {
        let betweenParser: Parser<StringInput, Character> = Combinators.between(
            Combinators.symbol("("),
            Combinators.digit(),
            Combinators.symbol(")")
        )
        let input = StringInput("")

        let result = betweenParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("(")])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testBetweenFailureOnMissingOpen() {
        let betweenParser: Parser<StringInput, Character> = Combinators.between(
            Combinators.symbol("("),
            Combinators.digit(),
            Combinators.symbol(")")
        )
        let input = StringInput("1)")

        let result = betweenParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("(")])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testBetweenFailureOnMissingClose() {
        let betweenParser: Parser<StringInput, Character> = Combinators.between(
            Combinators.symbol("("),
            Combinators.digit(),
            Combinators.symbol(")")
        )
        let input = StringInput("(1")

        let result = betweenParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value(")")])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testBetweenFailure() {
        let betweenParser: Parser<StringInput, Character> = Combinators.between(
            Combinators.symbol("("),
            Combinators.digit(),
            Combinators.symbol(")")
        )
        let input = StringInput("(A")

        let result = betweenParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testCountSuccess() {
        let countParser: Parser<StringInput, [Character]> = Combinators.count(
            Combinators.digit(),
            count: 3
        )
        let input = StringInput("123")

        let result = countParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testCountFailureMissingCount() {
        let countParser: Parser<StringInput, [Character]> = Combinators.count(
            Combinators.digit(),
            count: 3
        )
        let input = StringInput("12")

        let result = countParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testCountFailureWithParse() {
        let countParser: Parser<StringInput, [Character]> = Combinators.count(
            Combinators.digit(),
            count: 3
        )
        let input = StringInput("A123")

        let result = countParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testCountFailureWithMoreInput() {
        let countParser: Parser<StringInput, [Character]> = Combinators.count(
            Combinators.digit(),
            count: 3
        )
        let input = StringInput("1234")

        let result = countParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.empty])
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testEndBySuccess() {
        let endByParser: Parser<StringInput, [Character]> = Combinators.endBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A2A3A")

        let result = endByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testEndByFailureWithOnlyValue() {
        let endByParser: Parser<StringInput, [Character]> = Combinators.endBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1")

        let result = endByParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testEndBySuccessWithEmptyInput() {
        let endByParser: Parser<StringInput, [Character]> = Combinators.endBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("")

        let result = endByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndByFailureWithValue() {
        let endByParser: Parser<StringInput, [Character]> = Combinators.endBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1")

        let result = endByParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testEndByFailureWithSeparator() {
        let endByParser: Parser<StringInput, [Character]> = Combinators.endBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("A")

        let result = endByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndByFailure() {
        let endByParser: Parser<StringInput, [Character]> = Combinators.endBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("B")

        let result = endByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndBy1Success() {
        let endBy1Parser: Parser<StringInput, [Character]> = Combinators.endBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A2A3A")

        let result = endBy1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testEndBy1FailureWithOnlyValue() {
        let endBy1Parser: Parser<StringInput, [Character]> = Combinators.endBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1")

        let result = endBy1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testEndBy1FailureWithEmptyInput() {
        let endBy1Parser: Parser<StringInput, [Character]> = Combinators.endBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("")

        let result = endBy1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndBy1SuccessWithValueAndSeparator() {
        let endBy1Parser: Parser<StringInput, [Character]> = Combinators.endBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A")

        let result = endBy1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testEndBy1FailureWithSeparator() {
        let endBy1Parser: Parser<StringInput, [Character]> = Combinators.endBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("A")

        let result = endBy1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndBy1Failure() {
        let endBy1Parser: Parser<StringInput, [Character]> = Combinators.endBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("B")

        let result = endBy1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndBySuccess() {
        let sepEndByParser: Parser<StringInput, [Character]> = Combinators.sepEndBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A2A3A")

        let result = sepEndByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testSepEndBySuccessWithOnlyValue() {
        let sepEndByParser: Parser<StringInput, [Character]> = Combinators.sepEndBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1")

        let result = sepEndByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testSepEndBySuccessWithEmptyInput() {
        let sepEndByParser: Parser<StringInput, [Character]> = Combinators.sepEndBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("")

        let result = sepEndByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndBySuccessWithValueAndSeparator() {
        let sepEndByParser: Parser<StringInput, [Character]> = Combinators.sepEndBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A")

        let result = sepEndByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testSepEndByFailureWithSeparator() {
        let sepEndByParser: Parser<StringInput, [Character]> = Combinators.sepEndBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("A")

        let result = sepEndByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndByFailure() {
        let sepEndByParser: Parser<StringInput, [Character]> = Combinators.sepEndBy(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("B")

        let result = sepEndByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndBy1Success() {
        let sepEndBy1Parser: Parser<StringInput, [Character]> = Combinators.sepEndBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A2A3A")

        let result = sepEndBy1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testSepEndBy1SuccessWithOnlyValue() {
        let sepEndBy1Parser: Parser<StringInput, [Character]> = Combinators.sepEndBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1")

        let result = sepEndBy1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testSepEndBy1FailureWithEmptyInput() {
        let sepEndBy1Parser: Parser<StringInput, [Character]> = Combinators.sepEndBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("")

        let result = sepEndBy1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndBy1SuccessWithValueAndSeparator() {
        let sepEndBy1Parser: Parser<StringInput, [Character]> = Combinators.sepEndBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("1A")

        let result = sepEndBy1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testSepEndBy1FailureWithSeparator() {
        let sepEndBy1Parser: Parser<StringInput, [Character]> = Combinators.sepEndBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("A")

        let result = sepEndBy1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndBy1Failure() {
        let sepEndBy1Parser: Parser<StringInput, [Character]> = Combinators.sepEndBy1(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("B")

        let result = sepEndBy1Parser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testManyTillSuccess() {
        let manyTillParser: Parser<StringInput, [Character]> = Combinators.manyTill(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("123A")

        let result = manyTillParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1", "2", "3"])
        XCTAssertEqual(remainingInput.position, 4)
    }

    func testManyTillSuccessWithNoValues() {
        let manyTillParser: Parser<StringInput, [Character]> = Combinators.manyTill(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("A")

        let result = manyTillParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testManyTillFailureWithNoEndValue() {
        let manyTillParser: Parser<StringInput, [Character]> = Combinators.manyTill(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("123")

        let result = manyTillParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A")])
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testManyTillFailureWithUnexpectedInput() {
        let manyTillParser: Parser<StringInput, [Character]> = Combinators.manyTill(
            Combinators.digit(),
            Combinators.symbol("A")
        )
        let input = StringInput("B")

        let result = manyTillParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A"), Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    static var allTests = [
        ("testIsLetterSuccess", testIsLetterSuccess),
        ("testIsLetterFailure", testIsLetterFailure),
        ("testIsDigitSuccess", testIsDigitSuccess),
        ("testIsDigitFailure", testIsDigitFailure),
        ("testStringSuccess", testStringSuccess),
        ("testStringFailure", testStringFailure),
        ("testStringEmptyReturnValueSuccess", testStringEmptyReturnValueSuccess),
        ("testStringEmptyReturnValueFailure", testStringEmptyReturnValueFailure),
        ("testManySuccess", testManySuccess),
        ("testManySuccessWithEmptyInput", testManySuccessWithEmptyInput),
        ("testManyFailure", testManyFailure),
        ("testMany1Success", testMany1Success),
        ("testMany1FailureWithEmptyInput", testMany1FailureWithEmptyInput),
        ("testMany1SuccessComplex", testMany1SuccessComplex),
        ("testMany1Failure", testMany1Failure),
        ("testSkipManySuccess", testSkipManySuccess),
        ("testSkipManySuccessWithEmptyInput", testSkipManySuccessWithEmptyInput),
        ("testSkipManyFailure", testSkipManyFailure),
        ("testSkipMany1Success", testSkipMany1Success),
        ("testSkipMany1FailureWithEmptyInput", testSkipMany1FailureWithEmptyInput),
        ("testSkipMany1Failure", testSkipMany1Failure),
        ("testOptionOptionalWithParserSuccess", testOptionOptionalWithParserSuccess),
        ("testOptionOptionalWithParserFailure", testOptionOptionalWithParserFailure),
        ("testOptionAndValueWithParserSuccess", testOptionAndValueWithParserSuccess),
        ("testOptionAndValueWithParserFailure", testOptionAndValueWithParserFailure),
        ("testOptionalAndEmptyWithParserSuccess", testOptionalAndEmptyWithParserSuccess),
        ("testOptionalAndEmptyWithParserFailure", testOptionalAndEmptyWithParserFailure),
        ("testChainrSuccess", testChainrSuccess),
        ("testChainrSuccessWithOneOperand", testChainrSuccessWithOneOperand),
        ("testChainrSuccessWithEmptyInput", testChainrSuccessWithEmptyInput),
        ("testChainrFailure", testChainrFailure),
        ("testChainr1Success", testChainr1Success),
        ("testChainr1SuccessWithOnlyOperand", testChainr1SuccessWithOnlyOperand),
        ("testChainr1FailureWithEmptyInput", testChainr1FailureWithEmptyInput),
        ("testChainr1Failure", testChainr1Failure),
        ("testChainlSuccess", testChainlSuccess),
        ("testChainlSuccessWithOneOperand", testChainlSuccessWithOneOperand),
        ("testChainlSuccessWithEmptyInput", testChainlSuccessWithEmptyInput),
        ("testChainlFailure", testChainlFailure),
        ("testChainl1Success", testChainl1Success),
        ("testChainl1SuccessWithOnlyOperand", testChainl1SuccessWithOnlyOperand),
        ("testChainl1FailureWithEmptyInput", testChainl1FailureWithEmptyInput),
        ("testChainl1Failure", testChainl1Failure),
        ("testSepBySuccess", testSepBySuccess),
        ("testSepBySuccessWithOnlyValue", testSepBySuccessWithOnlyValue),
        ("testSepBySuccessWithEmptyInput", testSepBySuccessWithEmptyInput),
        ("testSepByFailureWithValueAndSeparator", testSepByFailureWithValueAndSeparator),
        ("testSepByFailureWithSeparator", testSepByFailureWithSeparator),
        ("testSepByFailure", testSepByFailure),
        ("testSepBy1Success", testSepBy1Success),
        ("testSepBy1SuccessWithOnlyValue", testSepBy1SuccessWithOnlyValue),
        ("testSepBy1FailureWithEmptyInput", testSepBy1FailureWithEmptyInput),
        ("testSepBy1FailureWithValueAndSeparator", testSepBy1FailureWithValueAndSeparator),
        ("testSepBy1FailureWithSeparator", testSepBy1FailureWithSeparator),
        ("testSepBy1Failure", testSepBy1Failure),
        ("testBetweenSuccess", testBetweenSuccess),
        ("testBetweenFailureOnEmptyInput", testBetweenFailureOnEmptyInput),
        ("testBetweenFailureOnMissingOpen", testBetweenFailureOnMissingOpen),
        ("testBetweenFailureOnMissingClose", testBetweenFailureOnMissingClose),
        ("testBetweenFailure", testBetweenFailure),
        ("testCountSuccess", testCountSuccess),
        ("testCountFailureMissingCount", testCountFailureMissingCount),
        ("testCountFailureWithParse", testCountFailureWithParse),
        ("testCountFailureWithMoreInput", testCountFailureWithMoreInput),
        ("testEndBySuccess", testEndBySuccess),
        ("testEndByFailureWithOnlyValue", testEndByFailureWithOnlyValue),
        ("testEndBySuccessWithEmptyInput", testEndBySuccessWithEmptyInput),
        ("testEndByFailureWithValue", testEndByFailureWithValue),
        ("testEndByFailureWithSeparator", testEndByFailureWithSeparator),
        ("testEndByFailure", testEndByFailure),
        ("testEndBy1Success", testEndBy1Success),
        ("testEndBy1FailureWithOnlyValue", testEndBy1FailureWithOnlyValue),
        ("testEndBy1FailureWithEmptyInput", testEndBy1FailureWithEmptyInput),
        ("testEndBy1SuccessWithValueAndSeparator", testEndBy1SuccessWithValueAndSeparator),
        ("testEndBy1FailureWithSeparator", testEndBy1FailureWithSeparator),
        ("testEndBy1Failure", testEndBy1Failure),
        ("testSepEndBySuccess", testSepEndBySuccess),
        ("testSepEndBySuccessWithOnlyValue", testSepEndBySuccessWithOnlyValue),
        ("testSepEndBySuccessWithEmptyInput", testSepEndBySuccessWithEmptyInput),
        ("testSepEndBySuccessWithValueAndSeparator", testSepEndBySuccessWithValueAndSeparator),
        ("testSepEndByFailureWithSeparator", testSepEndByFailureWithSeparator),
        ("testSepEndByFailure", testSepEndByFailure),
        ("testSepEndBy1Success", testSepEndBy1Success),
        ("testSepEndBy1SuccessWithOnlyValue", testSepEndBy1SuccessWithOnlyValue),
        ("testSepEndBy1FailureWithEmptyInput", testSepEndBy1FailureWithEmptyInput),
        ("testSepEndBy1SuccessWithValueAndSeparator", testSepEndBy1SuccessWithValueAndSeparator),
        ("testSepEndBy1FailureWithSeparator", testSepEndBy1FailureWithSeparator),
        ("testSepEndBy1Failure", testSepEndBy1Failure),
        ("testManyTillSuccess", testManyTillSuccess),
        ("testManyTillSuccessWithNoValues", testManyTillSuccessWithNoValues),
        ("testManyTillFailureWithNoEndValue", testManyTillFailureWithNoEndValue),
        ("testManyTillFailureWithUnexpectedInput", testManyTillFailureWithUnexpectedInput)

    ]
}
// swiftlint:enable type_body_length file_length
