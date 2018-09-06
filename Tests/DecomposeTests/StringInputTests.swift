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

internal final class StringInputTests: XCTestCase {
    func testInit() {
        let input = StringInput("Hello, World!")

        XCTAssertEqual(input.position, 0)
        XCTAssertEqual(input.peek(), "H")
        XCTAssertFalse(input.isEmpty)
        // Still at the 0 position
        XCTAssertEqual(input.position, 0)
    }

    func testInitWithPosition() {
        let input = StringInput("Hello, World!", position: 1)

        XCTAssertEqual(input.position, 1)
        XCTAssertEqual(input.peek(), "e")
        XCTAssertFalse(input.isEmpty)
        // Still at the 1 position
        XCTAssertEqual(input.position, 1)
    }

    func testPeekWithCount() {
        let input = StringInput("Hello, World!")

        XCTAssertEqual(input.position, 0)
        XCTAssertEqual(String(input.peek(count: 5)), "Hello")
        // Still at the 0 position
        XCTAssertEqual(input.position, 0)
    }

    func testOriginalPositionNotAt0AndPeekWithCount() {
        let input = StringInput("Hello, World!", position: 7)

        XCTAssertEqual(input.position, 7)
        XCTAssertEqual(String(input.peek(count: 5)), "World")
        // Still at the 0 position
        XCTAssertEqual(input.position, 7)
    }

    func testConsume() {
        let originalInput = StringInput("Hello, World!")
        let newInput = originalInput.consume()

        XCTAssertEqual(newInput.peek(), "e")
        XCTAssertEqual(originalInput.peek(), "H")

        XCTAssertEqual(newInput.position, 1)
        XCTAssertEqual(originalInput.position, 0)
    }

    func testOriginalPositionNotAt0AndConsume() {
        let originalInput = StringInput("Hello, World!", position: 7)
        let newInput = originalInput.consume()

        XCTAssertEqual(newInput.peek(), "o")
        XCTAssertEqual(originalInput.peek(), "W")

        XCTAssertEqual(newInput.position, 8)
        XCTAssertEqual(originalInput.position, 7)
    }

    func testConsumeWithCount() {
        let originalInput = StringInput("Hello, World!")
        let newInput = originalInput.consume(count: 5)

        XCTAssertEqual(newInput.peek(), ",")
        XCTAssertEqual(originalInput.peek(), "H")

        XCTAssertEqual(newInput.position, 5)
        XCTAssertEqual(originalInput.position, 0)
    }

    func testOriginalPositionNotAt0AndConsumeWithCount() {
        let originalInput = StringInput("Hello, World!", position: 5)
        let newInput = originalInput.consume(count: 2)

        XCTAssertEqual(newInput.peek(), "W")
        XCTAssertEqual(originalInput.peek(), ",")

        XCTAssertEqual(newInput.position, 7)
        XCTAssertEqual(originalInput.position, 5)
    }

    func testEmptyString() {
        let input = StringInput("")

        XCTAssertTrue(input.isEmpty)
        XCTAssertEqual(input.position, 0)
        XCTAssertNil(input.peek())
        XCTAssertEqual(input.peek(count: 2), [])
    }

    func testConsumeTillEndOfString() {
        let testString = "Hello, World!"

        var input = StringInput(testString)
        for (counter, char) in testString.enumerated() {
            XCTAssertFalse(input.isEmpty)
            XCTAssertEqual(input.position, counter)
            XCTAssertEqual(input.peek(), char)
            input = input.consume()
        }

        XCTAssertTrue(input.isEmpty)
        XCTAssertEqual(input.position, 13)
        XCTAssertNil(input.peek())
        XCTAssertEqual(input.peek(count: 1), [])
    }

    func testConsumePastEndOfString() {
        let originalInput = StringInput("Hello, World!")
        let newInput = originalInput.consume(count: 13)

        XCTAssertTrue(newInput.isEmpty)
        XCTAssertEqual(newInput.position, 13)

        let beyondEndOfStringInput = newInput.consume()
        XCTAssertTrue(beyondEndOfStringInput.isEmpty)
        XCTAssertEqual(beyondEndOfStringInput.position, 14)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInitWithPosition", testInitWithPosition),
        ("testPeekWithCount", testPeekWithCount),
        ("testOriginalPositionNotAt0AndPeekWithCount", testOriginalPositionNotAt0AndPeekWithCount),
        ("testConsume", testConsume),
        ("testOriginalPositionNotAt0AndConsume", testOriginalPositionNotAt0AndConsume),
        ("testConsumeWithCount", testConsumeWithCount),
        ("testOriginalPositionNotAt0AndConsumeWithCount", testOriginalPositionNotAt0AndConsumeWithCount),
        ("testEmptyString", testEmptyString),
        ("testConsumeTillEndOfString", testConsumeTillEndOfString),
        ("testConsumePastEndOfString", testConsumePastEndOfString)
    ]
}