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

internal final class StringInputTests: XCTestCase {
    func testInit() {
        let input = StringInput("Hello, World!")

        XCTAssertEqual(input.position, 0)
        XCTAssertEqual(input.current(), "H")
        XCTAssertTrue(input.isAvailable)
        // Still at the 0 position
        XCTAssertEqual(input.position, 0)
    }

    func testInitWithPosition() {
        let input = StringInput("Hello, World!", position: 1)

        XCTAssertEqual(input.position, 1)
        XCTAssertEqual(input.current(), "e")
        XCTAssertTrue(input.isAvailable)
        // Still at the 1 position
        XCTAssertEqual(input.position, 1)
    }

    func testAdvanced() {
        let originalInput = StringInput("Hello, World!")
        let newInput = originalInput.advanced()

        XCTAssertEqual(newInput.current(), "e")
        XCTAssertEqual(originalInput.current(), "H")

        XCTAssertEqual(newInput.position, 1)
        XCTAssertEqual(originalInput.position, 0)
    }

    func testOriginalPositionNotAt0AndAdvanced() {
        let originalInput = StringInput("Hello, World!", position: 7)
        let newInput = originalInput.advanced()

        XCTAssertEqual(newInput.current(), "o")
        XCTAssertEqual(originalInput.current(), "W")

        XCTAssertEqual(newInput.position, 8)
        XCTAssertEqual(originalInput.position, 7)
    }

    func testAdvancedTillEndOfString() {
        let testString = "Hello, World!"

        var input = StringInput(testString)
        for (counter, char) in testString.enumerated() {
            XCTAssertTrue(input.isAvailable)
            XCTAssertEqual(input.position, counter)
            XCTAssertEqual(input.current(), char)
            input = input.advanced()
        }

        XCTAssertFalse(input.isAvailable)
        XCTAssertEqual(input.position, 13)
        XCTAssertNil(input.current())
    }

    func testCharacterCountAndLineCount() {
        let testString = "Hi!\nBye!"

        var input = StringInput(testString)
        for (counter, char) in testString.enumerated() {
            XCTAssertTrue(input.isAvailable)
            XCTAssertEqual(input.position, counter)
            if counter > 3 {
                XCTAssertEqual(input.charCount, counter - 4)
                XCTAssertEqual(input.lineCount, 1)
            } else {
                XCTAssertEqual(input.charCount, counter)
                XCTAssertEqual(input.lineCount, 0)
            }
            XCTAssertEqual(input.current(), char)
            input = input.advanced()
        }

        XCTAssertFalse(input.isAvailable)
        XCTAssertEqual(input.position, 8)
        XCTAssertNil(input.current())
    }
}
