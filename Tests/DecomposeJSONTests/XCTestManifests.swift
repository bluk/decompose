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

import XCTest

internal extension JSONTests {
    static let __allTests = [
        ("testArray", testArray),
        ("testArrayEmpty", testArrayEmpty),
        ("testArrayEmptyWithSpaces", testArrayEmptyWithSpaces),
        ("testArrayFailureWithOnlyComma", testArrayFailureWithOnlyComma),
        ("testArrayFailureWithTrailingComma", testArrayFailureWithTrailingComma),
        ("testFalseValue", testFalseValue),
        ("testMinus0NumberValue", testMinus0NumberValue),
        ("testMinusBeforeNumberValue", testMinusBeforeNumberValue),
        ("testMinusZeroFollowedByNumberFailure", testMinusZeroFollowedByNumberFailure),
        ("testNullValue", testNullValue),
        ("testNumber0Value", testNumber0Value),
        ("testNumberFailureLeadingZero", testNumberFailureLeadingZero),
        ("testNumberManyDigitsValue", testNumberManyDigitsValue),
        ("testNumberValue", testNumberValue),
        ("testObject", testObject),
        ("testObjectFailureMissingClosingBrace", testObjectFailureMissingClosingBrace),
        ("testObjectFailureMultipleLinesMissingClosingBrace", testObjectFailureMultipleLinesMissingClosingBrace),
        ("testObjectFailureWithOnlyKey", testObjectFailureWithOnlyKey),
        ("testObjectFailureWithOnlyKeyAndColon", testObjectFailureWithOnlyKeyAndColon),
        ("testObjectFailureWithTrailingComma", testObjectFailureWithTrailingComma),
        ("testString", testString),
        ("testStringWithEscapeCharacters", testStringWithEscapeCharacters),
        ("testStringWithUnicode", testStringWithUnicode),
        ("testTrueValue", testTrueValue),
    ]
}

#if !os(macOS)
/// - Returns: All the tests in the module.
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(JSONTests.__allTests),
    ]
}
#endif
