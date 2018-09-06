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
        guard case let .success(value, remainder) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `A`")
            return
        }
        XCTAssertEqual(value, "A")
        XCTAssertEqual(remainder.position, 1)
    }

    func testIsLetterNotMatch() {
        let isLetter: Parser<StringInput, Character> = Combinators.isLetter()
        let input = StringInput("1A")

        let output = isLetter.parse(input)
        guard case let .error(error, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
        XCTAssertEqual(remainder, input)
    }

    func testIsDigit() {
        let isDigit: Parser<StringInput, Character> = Combinators.isDigit()
        let input = StringInput("12")

        let output = isDigit.parse(input)
        guard case let .success(value, remainder) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to be successful and consumption of `1`")
            return
        }
        XCTAssertEqual(value, "1")
        XCTAssertEqual(remainder.position, 1)
    }

    func testIsDigitNotMatch() {
        let isDigit: Parser<StringInput, Character> = Combinators.isDigit()
        let input = StringInput("A1")

        let output = isDigit.parse(input)
        guard case let .error(error, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
        XCTAssertEqual(remainder, input)
    }

    func testString() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.string("foo")
        let input = StringInput("foobar")

        let output = stringParser.parse(input)
        guard case let .success(value, remainder) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `foo`")
            return
        }
        XCTAssertEqual(String(value), "foo")
        XCTAssertEqual(remainder.position, 3)
    }

    func testStringWithNoMatch() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.string("foo")
        let input = StringInput("barfoo")

        let output = stringParser.parse(input)
        guard case let .error(error, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
        XCTAssertEqual(remainder, input)
    }

    func testStringEmptyReturn() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("foo")
        let input = StringInput("foobar")

        let output = stringParser.parse(input)
        guard case let .success(value, remainder) = output.reply, .consumed == output.state else {
            XCTFail("Expected parse to succeed and consumption of `foo`")
            return
        }
        XCTAssertEqual(value, [])
        XCTAssertEqual(remainder.position, 3)
    }

    func testStringEmptyReturnWithNoMatch() {
        let stringParser: Parser<StringInput, [Character]> = Combinators.stringEmptyReturn("foo")
        let input = StringInput("barfoo")

        let output = stringParser.parse(input)
        guard case let .error(error, remainder) = output.reply, .empty == output.state else {
            XCTFail("Expected parse to fail and no consumption")
            return
        }
        XCTAssertNil(error) // Currently nil, but should be a real value
        XCTAssertEqual(remainder, input)
    }

    static var allTests = [
        ("testIsLetter", testIsLetter),
        ("testIsLetterNotMatch", testIsLetterNotMatch),
        ("testIsDigit", testIsDigit),
        ("testIsDigitNotMatch", testIsDigitNotMatch),
        ("testString", testString),
        ("testStringWithNoMatch", testStringWithNoMatch)
    ]
}
