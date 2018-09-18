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

// swiftlint:disable type_body_length file_length

internal final class ParserTests: XCTestCase {

    func testPure() {
        let result = Parser.pure("Hello, World!").computeParse(StringInput("A"), [Symbol.empty])

        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "Hello, World!")
        XCTAssertEqual(remainingInput.current(), "A")
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSymbolSuccess() {
        let symbolParser = Parser<StringInput, Character>.symbol("H")

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
        let symbolParser = Parser<StringInput, Character>.symbol("H")

        let result = symbolParser.parse(StringInput("W"))
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("H")]))
    }

    func testSatisfySuccess() {
        let matchesF = Parser<StringInput, Character>.satisfy(conditionName: "f") { $0 == "f" }
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
        let matchesF = Parser<StringInput, Character>.satisfy(conditionName: "f") { $0 == "f" }
        let input = StringInput("bar")

        let result = matchesF.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.predicate(name: "f", { _ in true })]))
    }

    func testOrSuccess() {
        let matchesF = Parser<StringInput, Character>.symbol("f")
        let matchesB = Parser<StringInput, Character>.symbol("b")
        let choiceParser = Parser.or(matchesF, matchesB)

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

    func testOrFailure() {
        let matchesF = Parser<StringInput, Character>.symbol("f")
        let matchesB = Parser<StringInput, Character>.symbol("b")
        let choiceParser = Parser.or(matchesF, matchesB)
        let input = StringInput("xyz")

        let result = choiceParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("f"), Symbol<Character>.value("b")]))
    }

    func testChoiceSuccess() {
        let matchesF = Parser<StringInput, Character>.symbol("f")
        let matchesB = Parser<StringInput, Character>.symbol("b")
        let matchesO = Parser<StringInput, Character>.symbol("o")
        let choiceParser = Parser.choice([matchesF, matchesB, matchesO])

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

        let result3 = choiceParser.parse(StringInput("o"))
        guard case let .success(remainingInput3, value3) = result3 else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value3, "o")
        XCTAssertNil(remainingInput3.current())
        XCTAssertEqual(remainingInput3.position, 1)
    }

    func testChoiceFailure() {
        let matchesF = Parser<StringInput, Character>.symbol("f")
        let matchesB = Parser<StringInput, Character>.symbol("b")
        let matchesO = Parser<StringInput, Character>.symbol("o")
        let choiceParser = Parser.choice([matchesF, matchesB, matchesO])
        let input = StringInput("xyz")

        let result = choiceParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([
            Symbol<Character>.value("f"),
            Symbol<Character>.value("b"),
            Symbol<Character>.value("o"),
        ]))
    }

    func testMapSuccess() {
        let matches2 = Parser<StringInput, Character>.symbol("2")
        let mappedParser = Parser.map(matches2) { Int(String($0)) }

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
        let matches2 = Parser<StringInput, Character>.symbol("2")
        let mappedParser = Parser.map(matches2) { Int(String($0)) }

        let result = mappedParser.parse(StringInput("3"))
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("2")]))
    }

    func testApplySuccess() {
        let symbol2 = Parser<StringInput, Character>.symbol("2")
        let symbol3 = Parser<StringInput, Character>.symbol("3")
        let symbolTimes = Parser<StringInput, Character>.symbol("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
                    Int(String(first))! * Int(String(second))!
                }
            }
        }
        let applyParser = Parser.apply(Parser.apply(Parser.map(symbol2, func1), symbolTimes), symbol3)

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
        let symbol2 = Parser<StringInput, Character>.symbol("2")
        let symbol3 = Parser<StringInput, Character>.symbol("3")
        let symbolTimes = Parser<StringInput, Character>.symbol("*")
        let func1: (Character) -> (Character) -> (Character) -> Int? = { first in { _ in { second in
                    Int(String(first))! * Int(String(second))!
                }
            }
        }
        let applyParser = Parser.apply(Parser.apply(Parser.map(symbol2, func1), symbolTimes), symbol3)

        let result = applyParser.parse(StringInput("2+3"))
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 1)
        XCTAssertEqual(expectedSymbols, Set([Symbol<Character>.value("*")]))
    }

    func testFailSuccess() {
        let fail = Parser<StringInput, Character>.fail()
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
        let endOfInput = Parser<StringInput, Empty>.endOfInput()
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
        let endOfInput = Parser<StringInput, Empty>.endOfInput()
        let input = StringInput("A")

        let result = endOfInput.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(remainingInput.position, 0)
        XCTAssertEqual(expectedSymbols, Set([Symbol.empty]))
    }

    func testManySuccess() {
        let manyParser = Parser.many(Parser<StringInput, Character>.symbol("o"))
        let input = StringInput("ooo")

        let result = manyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["o", "o", "o"])
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testManySuccessWithAcceptEmptyParser() {
        let manyParser = Parser.many(Parser<StringInput, Character>.pure("o"))
        let input = StringInput("")

        let result = manyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testManySuccessWithAcceptEmptyParserFollowedByParser() {
        let manyParser = Parser<StringInput, [Character]>.sequence(
            [Parser.pure("o").many(), Parser.symbol("b").many()]
        )
        let input = StringInput("b")

        let result = manyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [[], ["b"]])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testManySuccessWithEmptyInput() {
        let manyParser = Parser.many(Parser<StringInput, Character>.symbol("o"))
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
        let manyParser = Parser.many(Parser<StringInput, Character>.symbol("o"))
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
        let many1Parser = Parser.many1(Parser<StringInput, Character>.symbol("o"))
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
        let many1Parser = Parser.many1(Parser<StringInput, Character>.symbol("o"))
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
        let many1Parser = Parser.many1(Combinators.Text<StringInput>.string("hello"))
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
        let many1Parser = Parser.many1(Parser<StringInput, Character>.symbol("o"))
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
        let skipManyParser = Parser.skipMany(Combinators.Text<StringInput>.letter())
        let input = StringInput("foobar")

        let result = skipManyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Empty.empty)
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testSkipManySuccessWithEmptyInput() {
        let skipManyParser = Parser.skipMany(Combinators.Text<StringInput>.letter())
        let input = StringInput("")

        let result = skipManyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Empty.empty)
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSkipManyFailure() {
        let skipManyParser = Parser.skipMany(Combinators.Text<StringInput>.letter())
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
        let skipMany1Parser = Parser.skipMany1(Combinators.Text<StringInput>.letter())
        let input = StringInput("foobar")

        let result = skipMany1Parser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, Empty.empty)
        XCTAssertEqual(remainingInput.position, 6)
    }

    func testSkipMany1FailureWithEmptyInput() {
        let skipMany1Parser = Parser.skipMany1(Combinators.Text<StringInput>.letter())
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
        let skipMany1Parser = Parser.skipMany1(Combinators.Text<StringInput>.letter())
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
        let optParser = Parser.optionOptional(Combinators.Text<StringInput>.letter())
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
        let optParser = Parser.optionOptional(Combinators.Text<StringInput>.letter())
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
        let optParser = Parser.option(Combinators.Text<StringInput>.letter(), "A")
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
        let optParser = Parser.option(Combinators.Text<StringInput>.letter(), "A")
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
        let optParser = Parser.optional(Combinators.Text<StringInput>.letter())
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
        let optParser = Parser.optional(Combinators.Text<StringInput>.letter())
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
        let chainrParser = Parser.chainr(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainrParser = Parser.chainr(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainrParser = Parser.chainr(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainrParser = Parser.chainr(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainr1Parser = Parser.chainr1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let chainr1Parser = Parser.chainr1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let chainr1Parser = Parser.chainr1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let chainr1Parser = Parser.chainr1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let chainlParser = Parser.chainl(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainlParser = Parser.chainl(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainlParser = Parser.chainl(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainlParser = Parser.chainl(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-")),
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
        let chainl1Parser = Parser.chainl1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let chainl1Parser = Parser.chainl1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let chainl1Parser = Parser.chainl1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let chainl1Parser = Parser.chainl1(
            Parser.apply(Parser.pure(intFunc), Combinators.Text<StringInput>.digit()),
            Parser.apply(Parser.pure(subtractFunc), Parser<StringInput, Character>.symbol("-"))
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
        let sepByParser = Parser.sepBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepByParser = Parser.sepBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepByParser = Parser.sepBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepByParser = Parser.sepBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepByParser = Parser.sepBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("A")

        let result = sepByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true }), Symbol.empty])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepByFailure() {
        let sepByParser = Parser.sepBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("B")

        let result = sepByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true }), Symbol.empty])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepBy1Success() {
        let sepBy1Parser = Parser.sepBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepBy1Parser = Parser.sepBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepBy1Parser = Parser.sepBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepBy1Parser = Parser.sepBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepBy1Parser = Parser.sepBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepBy1Parser = Parser.sepBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let betweenParser = Parser.between(
            Parser<StringInput, Character>.symbol("("),
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol(")")
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
        let betweenParser = Parser.between(
            Parser<StringInput, Character>.symbol("("),
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol(")")
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
        let betweenParser = Parser.between(
            Parser<StringInput, Character>.symbol("("),
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol(")")
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
        let betweenParser = Parser.between(
            Parser<StringInput, Character>.symbol("("),
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol(")")
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
        let betweenParser = Parser.between(
            Parser<StringInput, Character>.symbol("("),
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol(")")
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
        let countParser = Parser.count(
            Combinators.Text<StringInput>.digit(),
            3
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

    func testCountSuccessWithAcceptEmptyParser() {
        let countParser = Parser.count(
            Parser<StringInput, Character>.pure("A"),
            3
        )
        let input = StringInput("")

        let result = countParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["A", "A", "A"])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testCountSuccessWithAcceptEmptyParserInSequence() {
        let countParser = Parser.sequence([
            Parser.count(Parser<StringInput, Character>.pure("A"), 3),
            Parser.count(Parser<StringInput, Character>.symbol("B"), 1),
        ])
        let input = StringInput("B")

        let result = countParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [["A", "A", "A"], ["B"]])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testCountFailureMissingCount() {
        let countParser = Parser.count(
            Combinators.Text<StringInput>.digit(),
            3
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
        let countParser = Parser.count(
            Combinators.Text<StringInput>.digit(),
            3
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

    func testCountFailureWithParseButSameCount() {
        let countParser = Parser.count(
            Parser<StringInput, Character>.symbol("1"),
            3
        )
        let input = StringInput("11C")

        let result = countParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("1")])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testCountFailureWithMoreInput() {
        let countParser = Parser.count(
            Combinators.Text<StringInput>.digit(),
            3
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
        let endByParser = Parser.endBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let endByParser = Parser.endBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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

    func testEndBySuccessWithEmptyInput() {
        let endByParser = Parser.endBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let endByParser = Parser.endBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let endByParser = Parser.endBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("A")

        let result = endByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true }), Symbol.empty])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndByFailure() {
        let endByParser = Parser.endBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("B")

        let result = endByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true }), Symbol.empty])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testEndBy1Success() {
        let endBy1Parser = Parser.endBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let endBy1Parser = Parser.endBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("1")

        let result = endBy1Parser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testEndBy1FailureWithEmptyInput() {
        let endBy1Parser = Parser.endBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let endBy1Parser = Parser.endBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let endBy1Parser = Parser.endBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let endBy1Parser = Parser.endBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndByParser = Parser.sepEndBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndByParser = Parser.sepEndBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndByParser = Parser.sepEndBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndByParser = Parser.sepEndBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("1A")

        let result = sepEndByParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["1"])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testSepEndByFailureWithSeparator() {
        let sepEndByParser = Parser.sepEndBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("A")

        let result = sepEndByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true }), Symbol.empty])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndByFailure() {
        let sepEndByParser = Parser.sepEndBy(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("B")

        let result = sepEndByParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "digit", { _ in true }), Symbol.empty])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSepEndBy1Success() {
        let sepEndBy1Parser = Parser.sepEndBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndBy1Parser = Parser.sepEndBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndBy1Parser = Parser.sepEndBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndBy1Parser = Parser.sepEndBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndBy1Parser = Parser.sepEndBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let sepEndBy1Parser = Parser.sepEndBy1(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let manyTillParser = Parser.manyTill(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.symbol("A")
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

    func testManyTillSuccessWithAcceptEmptyEndParser() {
        let manyTillParser = Parser.manyTill(
            Combinators.Text<StringInput>.digit(),
            Parser<StringInput, Character>.pure("A")
        )
        let input = StringInput("")

        let result = manyTillParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testManyTillSuccessWithAcceptEmptyManyParser() {
        let manyTillParser = Parser.manyTill(
            Parser<StringInput, Character>.pure("A"),
            Parser<StringInput, Character>.symbol("B")
        )
        let input = StringInput("B")

        let result = manyTillParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testManyTillSuccessWithAcceptEmptyManyAndParsers() {
        let manyTillParser = Parser.manyTill(
            Parser<StringInput, Character>.pure("A"),
            Parser<StringInput, Character>.pure("B")
        )
        let input = StringInput("")

        let result = manyTillParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testManyTillSuccessWithNoValues() {
        let manyTillParser = Parser.manyTill(
            Combinators.Text.digit(),
            Parser<StringInput, Character>.symbol("A")
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
        let manyTillParser = Parser.manyTill(
            Combinators.Text.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("123")

        let result = manyTillParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A")])
        XCTAssertEqual(remainingInput.position, 3)
    }

    func testManyTillFailureWithUnexpectedInput() {
        let manyTillParser = Parser.manyTill(
            Combinators.Text.digit(),
            Parser<StringInput, Character>.symbol("A")
        )
        let input = StringInput("B")

        let result = manyTillParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A"), Symbol.predicate(name: "digit", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testAnySuccess() {
        let anyParser = Parser<StringInput, Character>.any()
        let input = StringInput("1")

        let result = anyParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "1")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testAnyFailureWithUnavailableInput() {
        let anyParser = Parser<StringInput, Character>.any()
        let input = StringInput("")

        let result = anyParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.all])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testOneOfSuccess() {
        let oneOfParser = Parser<StringInput, Character>.oneOf(["A", "B"])
        let input = StringInput("B")

        let result = oneOfParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "B")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testOneOfFailure() {
        let oneOfParser = Parser<StringInput, Character>.oneOf(["A", "B"])
        let input = StringInput("C")

        let result = oneOfParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A"), Symbol.value("B")])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testOneOfFailureWithUnavailableInput() {
        let oneOfParser = Parser<StringInput, Character>.oneOf(["A", "B"])
        let input = StringInput("")

        let result = oneOfParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A"), Symbol.value("B")])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testNoneOfSuccess() {
        let noneOfParser = Parser<StringInput, Character>.noneOf(["A", "B"])
        let input = StringInput("1")

        let result = noneOfParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, "1")
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testNoneOfFailure() {
        let noneOfParser = Parser<StringInput, Character>.noneOf(["A", "B"])
        let input = StringInput("B")

        let result = noneOfParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "none of A, B", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testNoneOfFailureWithUnavailableInput() {
        let noneOfParser = Parser<StringInput, Character>.noneOf(["A", "B"])
        let input = StringInput("")

        let result = noneOfParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.predicate(name: "none of A, B", { _ in true })])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSequenceSuccess() {
        let sequenceParser = Parser.sequence([
            Parser<StringInput, Character>.symbol("A"),
            Parser<StringInput, Character>.symbol("B"),
        ])
        let input = StringInput("AB")

        let result = sequenceParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["A", "B"])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testSequenceSuccessWithEmptyAccept() {
        let sequenceParser = Parser.sequence([
            Parser<StringInput, Character>.symbol("A"),
            Parser<StringInput, Character>.pure("B"),
            Parser<StringInput, Character>.symbol("C"),
            Parser<StringInput, Character>.pure("D"),
        ])
        let input = StringInput("AC")

        let result = sequenceParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, ["A", "B", "C", "D"])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testSequenceFailureWithParseFailure() {
        let sequenceParser = Parser.sequence([
            Parser<StringInput, Character>.symbol("A"),
            Parser<StringInput, Character>.symbol("B"),
        ])
        let input = StringInput("AC")

        let result = sequenceParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("B")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testSequenceFailureWithUnavailableInput() {
        let sequenceParser = Parser.sequence([
            Parser<StringInput, Character>.symbol("A"),
            Parser<StringInput, Character>.symbol("B"),
        ])
        let input = StringInput("")

        let result = sequenceParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("A")])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testSequenceFailureWithMissingSequence() {
        let sequenceParser = Parser.sequence([
            Parser<StringInput, Character>.symbol("A"),
            Parser<StringInput, Character>.symbol("B"),
        ])
        let input = StringInput("A")

        let result = sequenceParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("B")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testTraverseSuccess() {
        let traverseParser = Parser.traverse(
            [
                Parser<StringInput, Character>.symbol("1"),
                Parser<StringInput, Character>.symbol("2"),
            ], { value in
                Int(String(value))!
            }
        )
        let input = StringInput("12")

        let result = traverseParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [1, 2])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testTraverseSuccessWithEmptyAccept() {
        let traverseParser = Parser.traverse(
            [
                Parser<StringInput, Character>.symbol("1"),
                Parser<StringInput, Character>.pure("2"),
                Parser<StringInput, Character>.symbol("3"),
                Parser<StringInput, Character>.pure("4"),
            ], { value in
                Int(String(value))!
            }
        )
        let input = StringInput("13")

        let result = traverseParser.parse(input)
        guard case let .success(remainingInput, value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, [1, 2, 3, 4])
        XCTAssertEqual(remainingInput.position, 2)
    }

    func testTraverseFailureWithParseFailure() {
        let traverseParser = Parser.traverse(
            [
                Parser<StringInput, Character>.symbol("1"),
                Parser<StringInput, Character>.symbol("2"),
            ], { value in
                Int(String(value))!
            }
        )
        let input = StringInput("13")

        let result = traverseParser.parse(input)
        guard case let .failure(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("2")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    func testTraverseFailureWithUnavailableInput() {
        let traverseParser = Parser.traverse(
            [
                Parser<StringInput, Character>.symbol("1"),
                Parser<StringInput, Character>.symbol("2"),
            ], { value in
                Int(String(value))!
            }
        )
        let input = StringInput("")

        let result = traverseParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("1")])
        XCTAssertEqual(remainingInput.position, 0)
    }

    func testTraverseFailureWithMissingSequence() {
        let traverseParser = Parser.traverse(
            [
                Parser<StringInput, Character>.symbol("1"),
                Parser<StringInput, Character>.symbol("2"),
            ], { value in
                Int(String(value))!
            }
        )
        let input = StringInput("1")

        let result = traverseParser.parse(input)
        guard case let .failureUnavailableInput(remainingInput, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(expectedSymbols, [Symbol.value("2")])
        XCTAssertEqual(remainingInput.position, 1)
    }

    static var allTests = [
        ("testPure", testPure),
        ("testSymbolSuccess", testSymbolSuccess),
        ("testSymbolFailure", testSymbolFailure),
        ("testSatisfySuccess", testSatisfySuccess),
        ("testSatisfyFailure", testSatisfyFailure),
        ("testOrSuccess", testOrSuccess),
        ("testOrFailure", testOrFailure),
        ("testChoiceSuccess", testChoiceSuccess),
        ("testChoiceFailure", testChoiceFailure),
        ("testMapSuccess", testMapSuccess),
        ("testMapFailure", testMapFailure),
        ("testApplySuccess", testApplySuccess),
        ("testApplyFailure", testApplyFailure),
        ("testFailSuccess", testFailSuccess),
        ("testEndOfInputSuccess", testEndOfInputSuccess),
        ("testEndOfInputFailure", testEndOfInputFailure),
        ("testManySuccess", testManySuccess),
        ("testManySuccessWithAcceptEmptyParser", testManySuccessWithAcceptEmptyParser),
        ("testManySuccessWithAcceptEmptyParserFollowedByParser", testManySuccessWithAcceptEmptyParserFollowedByParser),
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
        ("testCountSuccessWithAcceptEmptyParser", testCountSuccessWithAcceptEmptyParser),
        ("testCountSuccessWithAcceptEmptyParserInSequence", testCountSuccessWithAcceptEmptyParserInSequence),
        ("testCountFailureMissingCount", testCountFailureMissingCount),
        ("testCountFailureWithParse", testCountFailureWithParse),
        ("testCountFailureWithParseButSameCount", testCountFailureWithParseButSameCount),
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
        ("testManyTillSuccessWithAcceptEmptyEndParser", testManyTillSuccessWithAcceptEmptyEndParser),
        ("testManyTillSuccessWithAcceptEmptyManyParser", testManyTillSuccessWithAcceptEmptyManyParser),
        ("testManyTillSuccessWithAcceptEmptyManyAndParsers", testManyTillSuccessWithAcceptEmptyManyAndParsers),
        ("testManyTillSuccessWithNoValues", testManyTillSuccessWithNoValues),
        ("testManyTillFailureWithNoEndValue", testManyTillFailureWithNoEndValue),
        ("testManyTillFailureWithUnexpectedInput", testManyTillFailureWithUnexpectedInput),
        ("testAnySuccess", testAnySuccess),
        ("testAnyFailureWithUnavailableInput", testAnyFailureWithUnavailableInput),
        ("testOneOfSuccess", testOneOfSuccess),
        ("testOneOfFailure", testOneOfFailure),
        ("testOneOfFailureWithUnavailableInput", testOneOfFailureWithUnavailableInput),
        ("testNoneOfSuccess", testNoneOfSuccess),
        ("testNoneOfFailure", testNoneOfFailure),
        ("testNoneOfFailureWithUnavailableInput", testNoneOfFailureWithUnavailableInput),
        ("testSequenceSuccess", testSequenceSuccess),
        ("testSequenceSuccessWithEmptyAccept", testSequenceSuccessWithEmptyAccept),
        ("testSequenceFailureWithParseFailure", testSequenceFailureWithParseFailure),
        ("testSequenceFailureWithUnavailableInput", testSequenceFailureWithUnavailableInput),
        ("testSequenceFailureWithMissingSequence", testSequenceFailureWithMissingSequence),
        ("testTraverseSuccess", testTraverseSuccess),
        ("testTraverseSuccessWithEmptyAccept", testTraverseSuccessWithEmptyAccept),
        ("testTraverseFailureWithParseFailure", testTraverseFailureWithParseFailure),
        ("testTraverseFailureWithUnavailableInput", testTraverseFailureWithUnavailableInput),
        ("testTraverseFailureWithMissingSequence", testTraverseFailureWithMissingSequence),
    ]
}
// swiftlint:enable type_body_length file_length
