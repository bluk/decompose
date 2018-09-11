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

    func testOptWithParserSuccess() {
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

    func testOptWithParserFailure() {
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

    func testOptAndValueWithParserSuccess() {
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

    func testOptAndValueWithParserFailure() {
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
        ("testOptWithParserSuccess", testOptWithParserSuccess),
        ("testOptWithParserFailure", testOptWithParserFailure),
        ("testOptAndValueWithParserSuccess", testOptAndValueWithParserSuccess),
        ("testOptAndValueWithParserFailure", testOptAndValueWithParserFailure),
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
        ("testChainl1Failure", testChainl1Failure)
    ]
}
// swiftlint:enable type_body_length file_length
