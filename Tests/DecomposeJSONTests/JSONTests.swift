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

@testable import DecomposeJSON
import XCTest

// swiftlint:disable type_body_length

internal final class JSONTests: XCTestCase {
    func testTrueValue() {
        let input = "true"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.literalTrue)
    }

    func testFalseValue() {
        let input = "false"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.literalFalse)
    }

    func testNullValue() {
        let input = "null"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.literalNull)
    }

    func testNumber0Value() {
        let input = "0"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.number("0", "", ""))
    }

    func testNumberValue() {
        for number in 1...9 {
            let input = "\(number)"
            let result = JSON.decode(input)
            guard case let .success(value) = result else {
                XCTFail("Expected parse to be successful.")
                return
            }
            XCTAssertEqual(value, JSONValue.number("\(number)", "", ""))
        }
    }

    func testNumberManyDigitsValue() {
        let input = "1234567890"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.number("1234567890", "", ""))
    }

    func testNumberFailureLeadingZero() {
        let input = "0123"
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 1)
        XCTAssertEqual(
            expectedSymbols, [
                "predicate(id: whitespace)",
                "empty",
                "value(.)",
                "value(e)",
                "value(E)",
                "predicate(id: newline)",
            ]
        )
    }

    func testMinusBeforeNumberValue() {
        let input = "-123"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.number("-123", "", ""))
    }

    func testMinus0NumberValue() {
        let input = "-0"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.number("-0", "", ""))
    }

    func testMinusZeroFollowedByNumberFailure() {
        let input = "-01"
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 2)
        XCTAssertEqual(
            expectedSymbols, [
                "predicate(id: whitespace)",
                "empty", "value(.)",
                "value(e)",
                "value(E)",
                "predicate(id: newline)",
            ]
        )
    }

    func testString() {
        let input = "\"Hello world!\""
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.string("Hello world!"))
    }

    func testStringWithEscapeCharacters() {
        let input = "\"Hello\\n\\\"world!\\\"\""
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.string("Hello\n\"world!\""))
    }

    func testStringWithUnicode() {
        let input = "\"\\u0041\""
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.string("\u{0041}"))
    }

    func testArrayEmpty() {
        let input = "[]"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.array([]))
    }

    func testArrayEmptyWithSpaces() {
        let input = "[    ]"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.array([]))
    }

    func testArray() {
        let input = "[ true  , false, null,\"A\",1   ]"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(
            value, JSONValue.array(
                [
                    JSONValue.literalTrue,
                    JSONValue.literalFalse,
                    JSONValue.literalNull,
                    JSONValue.string("A"),
                    JSONValue.number("1", "", ""),
                ]
            )
        )
    }

    func testArrayFailureWithTrailingComma() {
        let input = "[true, ]"
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 7)
        XCTAssertEqual(
            expectedSymbols, [
                "predicate(id: whitespace)",
                "predicate(id: newline)",
                "value(n)",
                "value(t)",
                "value(f)",
                "value(-)",
                "value([)",
                "value(0)",
                "value(\")",
                "value({)",
                "value(1)",
                "value(2)",
                "value(3)",
                "value(4)",
                "value(5)",
                "value(6)",
                "value(7)",
                "value(8)",
                "value(9)",
            ]
        )
    }

    func testArrayFailureWithOnlyComma() {
        let input = "[, ]"
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 1)
        XCTAssertEqual(
            expectedSymbols, [
                "predicate(id: whitespace)",
                "predicate(id: newline)",
                "value(n)",
                "value(t)",
                "value(f)",
                "value(-)",
                "value([)",
                "value(0)",
                "value(\")",
                "empty",
                "value(])",
                "value({)",
                "value(1)",
                "value(2)",
                "value(3)",
                "value(4)",
                "value(5)",
                "value(6)",
                "value(7)",
                "value(8)",
                "value(9)",
            ]
        )
    }

    func testObject() {
        let input = "{ \"A\": \"B\" }"
        let result = JSON.decode(input)
        guard case let .success(value) = result else {
            XCTFail("Expected parse to be successful.")
            return
        }
        XCTAssertEqual(value, JSONValue.object(["A": JSONValue.string("B")]))
    }

    func testObjectFailureWithTrailingComma() {
        let input = "{ , }"
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 2)
        XCTAssertEqual(
            expectedSymbols, [
                "predicate(id: whitespace)",
                "value(\")",
                "value(})",
                "empty",
                "predicate(id: newline)",
            ]
        )
    }

    func testObjectFailureWithOnlyKey() {
        let input = "{ \"A\" }"
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 6)
        XCTAssertEqual(expectedSymbols, ["value(:)"])
    }

    func testObjectFailureWithOnlyKeyAndColon() {
        let input = "{ \"A\"  : }"
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 9)
        XCTAssertEqual(
            expectedSymbols, [
                "value({)",
                "value(0)",
                "value(n)",
                "value(t)",
                "value(f)",
                "value([)",
                "value(\")",
                "predicate(id: whitespace)",
                "predicate(id: newline)",
                "value(-)",
                "value(1)",
                "value(2)",
                "value(3)",
                "value(4)",
                "value(5)",
                "value(6)",
                "value(7)",
                "value(8)",
                "value(9)",
            ]
        )
    }

    func testObjectFailureMissingClosingBrace() {
        let input = "{ "
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 0)
        XCTAssertEqual(charCount, 2)
        XCTAssertEqual(expectedSymbols, ["value(})"])
    }

    func testObjectFailureMultipleLinesMissingClosingBrace() {
        let input = "{\n\n "
        let result = JSON.decode(input)
        guard case let .failure(lineCount, charCount, expectedSymbols) = result else {
            XCTFail("Expected parse to fail.")
            return
        }
        XCTAssertEqual(lineCount, 2)
        XCTAssertEqual(charCount, 1)
        XCTAssertEqual(expectedSymbols, ["value(})"])
    }
}

// swiftlint:enable type_body_length
