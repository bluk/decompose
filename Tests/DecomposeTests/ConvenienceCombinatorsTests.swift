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
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `A`")
            return
        }
        XCTAssertEqual(value, "A")
        XCTAssertEqual(advancedInput.position, 1)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testIsLetterNotMatch() {
        let isLetter: Parser<StringInput, Character> = Combinators.isLetter()
        let input = StringInput("1A")

        let output = isLetter.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "1")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testIsDigit() {
        let isDigit: Parser<StringInput, Character> = Combinators.isDigit()
        let input = StringInput("12")

        let output = isDigit.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `1`")
            return
        }
        XCTAssertEqual(value, "1")
        XCTAssertEqual(advancedInput.position, 1)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testIsDigitNotMatch() {
        let isDigit: Parser<StringInput, Character> = Combinators.isDigit()
        let input = StringInput("A1")

        let output = isDigit.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "A")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testString() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.string("foo")
        let input = StringInput("foobar")

        let output = stringParser.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `foo`")
            return
        }
        XCTAssertEqual(String(value), "foo")
        XCTAssertEqual(advancedInput.position, 3)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 3)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testStringWithNoMatch() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.string("foo")
        let input = StringInput("barfoo")

        let output = stringParser.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "b")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testStringEmptyReturn() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("foo")
        let input = StringInput("foobar")

        let output = stringParser.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `foo`")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(advancedInput.position, 3)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 3)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testStringEmptyReturnWithNoMatch() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("foo")
        let input = StringInput("barfoo")

        let output = stringParser.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "b")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testMany1() {
        let many1Parser: Parser<StringInput, [Character]> = Combinators.many1(Combinators.char("o"))
        let input = StringInput("oooh")

        let output = many1Parser.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `ooo`")
            return
        }
        XCTAssertEqual(String(value), "ooo")
        XCTAssertEqual(advancedInput.position, 3)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "h")
        XCTAssertEqual(msg.position, 3)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testMany1Complex() {
        let many1Parser: Parser<StringInput, [[Character]]> = Combinators.many1(Combinators.string("hello"))
        let input = StringInput("hellohellohe")

        let output = many1Parser.parse(input)
        guard case let .success(value, advancedInput, msgGenerator) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `ooo`")
            return
        }
        XCTAssertEqual(value.count, 2)
        XCTAssertEqual(String(value[0]), "hello")
        XCTAssertEqual(String(value[1]), "hello")
        XCTAssertEqual(advancedInput.position, 10)
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "")
        XCTAssertEqual(msg.position, 10)
        XCTAssertEqual(msg.expectedProductions, [])
    }

    func testMany1NoMatch() {
        let many1Parser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("o")
        let input = StringInput("boo")

        let output = many1Parser.parse(input)
        guard case let .error(msgGenerator) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        let msg = msgGenerator()
        XCTAssertEqual(msg.unexpectedInput, "b")
        XCTAssertEqual(msg.position, 0)
        XCTAssertEqual(msg.expectedProductions, [])
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
