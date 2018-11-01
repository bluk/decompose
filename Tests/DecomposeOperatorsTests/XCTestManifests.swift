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

extension OperatorsTests {
    static let __allTests = [
        ("testApplySuccessAsOperator", testApplySuccessAsOperator),
        ("testChoiceSuccessAsOperator", testChoiceSuccessAsOperator),
        ("testMapSuccessAsOperator", testMapSuccessAsOperator),
    ]
}

#if !os(macOS)
/// - Returns: All the tests in the module.
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(OperatorsTests.__allTests),
    ]
}
#endif
