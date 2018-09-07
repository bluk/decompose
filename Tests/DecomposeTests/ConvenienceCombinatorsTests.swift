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

internal final class ConvenienceCombinatorsTests: XCTestCase {

    func testIsLetter() {
        let isLetter: Parser<StringInput, Character> = Combinators.isLetter()

        let output = isLetter.parse(StringInput("AB"))
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `A`")
            return
        }
        XCTAssertEqual(value, "A")
        XCTAssertEqual(remainder.position, 1)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testIsLetterNotMatch() {
        let isLetter: Parser<StringInput, Character> = Combinators.isLetter()
        let input = StringInput("1A")

        let output = isLetter.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "1")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testIsDigit() {
        let isDigit: Parser<StringInput, Character> = Combinators.isDigit()
        let input = StringInput("12")

        let output = isDigit.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `1`")
            return
        }
        XCTAssertEqual(value, "1")
        XCTAssertEqual(remainder.position, 1)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testIsDigitNotMatch() {
        let isDigit: Parser<StringInput, Character> = Combinators.isDigit()
        let input = StringInput("A1")

        let output = isDigit.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "A")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testString() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.string("foo")
        let input = StringInput("foobar")

        let output = stringParser.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `foo`")
            return
        }
        XCTAssertEqual(String(value), "foo")
        XCTAssertEqual(remainder.position, 3)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 3)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testStringWithNoMatch() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.string("foo")
        let input = StringInput("barfoo")

        let output = stringParser.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "b")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testStringEmptyReturn() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("foo")
        let input = StringInput("foobar")

        let output = stringParser.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `foo`")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainder.position, 3)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 3)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testStringEmptyReturnWithNoMatch() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("foo")
        let input = StringInput("barfoo")

        let output = stringParser.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "b")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testMany1() {
        let many1Parser: Parser<StringInput, [Character]> = Combinators.many1(Combinators.char("o"))
        let input = StringInput("oooh")

        let output = many1Parser.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `ooo`")
            return
        }
        XCTAssertEqual(String(value), "ooo")
        XCTAssertEqual(remainder.position, 3)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "h")
        XCTAssertEqual(error.position, 3)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testMany1Complex() {
        let many1Parser: Parser<StringInput, [[Character]]> = Combinators.many1(Combinators.string("hello"))
        let input = StringInput("hellohellohe")

        let output = many1Parser.parse(input)
        guard case let .success(value, remainder, errorGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `ooo`")
            return
        }
        XCTAssertEqual(value.count, 2)
        XCTAssertEqual(String(value[0]), "hello")
        XCTAssertEqual(String(value[1]), "hello")
        XCTAssertEqual(remainder.position, 10)
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "")
        XCTAssertEqual(error.position, 10)
        XCTAssertEqual(error.expectedProductions, [])
    }

    func testMany1NoMatch() {
        let many1Parser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("o")
        let input = StringInput("boo")

        let output = many1Parser.parse(input)
        guard case let .error(errorGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let error = errorGenerator()
        XCTAssertEqual(error.unexpectedInput, "b")
        XCTAssertEqual(error.position, 0)
        XCTAssertEqual(error.expectedProductions, [])
    }

    static var allTests = [
        ("testIsLetter", testIsLetter),
        ("testIsLetterNotMatch", testIsLetterNotMatch),
        ("testIsDigit", testIsDigit),
        ("testIsDigitNotMatch", testIsDigitNotMatch),
        ("testString", testString),
        ("testStringWithNoMatch", testStringWithNoMatch),
        ("testMany1", testMany1),
        ("testMany1Complex", testMany1Complex),
        ("testMany1NoMatch", testMany1NoMatch)
    ]
}
