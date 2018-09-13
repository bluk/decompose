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

import Foundation

/// Convience methods to generate parsers
public extension Combinators {

    /// Text related parsers.
    enum Text {
        /// Returns a `Parser` which tests if the current element is a specific `Character`.
        ///
        /// - Parameters:
        ///     - value: The `Character` to test with.
        /// - Returns: A `Parser` which tests if the current element is a specific `Character`.
        public static func char<I>(_ value: Character) -> Parser<I, Character>
            where I.Element == Character {
            return Parser<I, Character>.satisfy(conditionName: "\"\(value)\"") { $0 == value }
        }

        /// Returns a `Parser` which tests if the current element is a letter.
        ///
        /// - Returns: A `Parser` which tests if the current element is a letter.
        public static func letter<I>() -> Parser<I, Character>
            where I.Element == Character {
            let characterSet = CharacterSet.letters
            #if swift(>=4.2)
            return Parser<I, Character>.satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
            #else
            // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
            return Parser<I, Character>.satisfy(conditionName: "letter") {
                !$0.unicodeScalars.contains { !characterSet.contains($0) }
            }
            #endif
        }

        /// Returns a `Parser` which tests if the current element is a digit.
        ///
        /// - Returns: A `Parser` which tests if the current element is a digit.
        public static func digit<I>() -> Parser<I, Character>
            where I.Element == Character {
            let characterSet = CharacterSet.decimalDigits
            #if swift(>=4.2)
            return Parser<I, Character>.satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
            #else
            // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
            return Parser<I, Character>.satisfy(conditionName: "digit") {
                !$0.unicodeScalars.contains { !characterSet.contains($0) }
            }
            #endif
        }

        /// Returns a `Parser` which matches a given string.
        ///
        /// - Parameters:
        ///     - value: The `String` to test with.
        /// - Returns: A `Parser` which matches a given string.
        public static func string<I>(_ value: String) -> Parser<I, String> where I.Element == Character {
            guard !value.isEmpty else {
                return Parser<I, String>.pure("")
            }

            let firstChar = value.first!
            return Parser<I, String>.symbol(firstChar)
                .andR(string(String(value.dropFirst())))
                .andR(Parser<I, String>.pure(value))
        }

        /// Returns a `Parser` which matches a given string. If successful, the returned value is an empty array.
        ///
        /// - Parameters:
        ///     - value: The `String` to test with.
        /// - Returns: A `Parser` which matches a given string. If successful, the returned value is an empty array.
        public static func stringEmptyReturnValue<I>(_ value: String)
            -> Parser<I, Empty> where I.Element == Character {
            guard !value.isEmpty else {
                return Parser<I, Empty>.pure(Empty.empty)
            }

            let firstChar = value.first!
            return Parser<I, Character>.symbol(firstChar)
                .andR(string(String(value.dropFirst())))
                .andR(Parser<I, Empty>.pure(Empty.empty))
        }
    }
}
