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

/// Convience methods to generate parsers.
public enum Combinators {
    /// Text related parsers.
    public enum Text<I> where I: Input, I.Element == Character {
        /// Returns a `Parser` which tests if the current element is a specific `Character`.
        ///
        /// - Parameters:
        ///     - value: The `Character` to test with.
        /// - Returns: A `Parser` which tests if the current element is a specific `Character`.
        public static func char(_ value: Character) -> Parser<I, Character> {
            return Parser<I, Character>.symbol(value)
        }

        /// Returns a `Parser` which tests if the current element is a letter.
        ///
        /// - Returns: A `Parser` which tests if the current element is a letter.
        public static func letter() -> Parser<I, Character> {
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
        public static func digit() -> Parser<I, Character> {
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

        /// Parses a non-zero digit.
        ///
        /// - Returns: A `Parser` which parses a non-zero digit character.
        public static func nonzeroDigit() -> Parser<I, Character> {
            return Parser<I, Character>.choice(
                [
                    Combinators.Text.char("1"),
                    Combinators.Text.char("2"),
                    Combinators.Text.char("3"),
                    Combinators.Text.char("4"),
                    Combinators.Text.char("5"),
                    Combinators.Text.char("6"),
                    Combinators.Text.char("7"),
                    Combinators.Text.char("8"),
                    Combinators.Text.char("9"),
                ]
            )
        }

        /// Parses a hexadecimal character.
        ///
        /// - Returns: A `Parser` which parses a hexadecimal character.
        public static func hexadecimal() -> Parser<I, Character> {
            return Parser<I, Character>.choice(
                [
                    Combinators.Text.char("0"),
                    Combinators.Text.char("1"),
                    Combinators.Text.char("2"),
                    Combinators.Text.char("3"),
                    Combinators.Text.char("4"),
                    Combinators.Text.char("5"),
                    Combinators.Text.char("6"),
                    Combinators.Text.char("7"),
                    Combinators.Text.char("8"),
                    Combinators.Text.char("9"),
                    Combinators.Text.char("A"),
                    Combinators.Text.char("B"),
                    Combinators.Text.char("C"),
                    Combinators.Text.char("D"),
                    Combinators.Text.char("E"),
                    Combinators.Text.char("F"),
                ]
            )
        }

        /// Parse a hexadecimal character and returns an `Int` value.
        ///
        /// - Returns: A `Parser` which parses a hexadecimal character and returns an `Int` value.
        public static func hexadecimalAsInt() -> Parser<I, Int> {
            return hexadecimal().map { Int(String($0), radix: 16)! }
        }

        /// Parses a positive or negative sign.
        ///
        /// - Returns: A `Parser` which parses a non-zero digit character.
        public static func sign() -> Parser<I, Character> {
            return Parser<I, Character>.choice(
                [
                    Combinators.Text.char("+"),
                    Combinators.Text.char("-"),
                ]
            )
        }

        /// Returns a `Parser` which matches a given string.
        ///
        /// - Parameters:
        ///     - value: The `String` to test with.
        /// - Returns: A `Parser` which matches a given string.
        public static func string(_ value: String) -> Parser<I, String> {
            guard !value.isEmpty else {
                return Parser<I, String>.pure("")
            }

            let firstChar = value.first!
            return Parser.symbol(firstChar)
                .andR(string(String(value.dropFirst())))
                .andR(Parser<I, String>.pure(value))
        }

        /// Returns a `Parser` which matches a given string. If successful, the returned value is an empty array.
        ///
        /// - Parameters:
        ///     - value: The `String` to test with.
        /// - Returns: A `Parser` which matches a given string. If successful, the returned value is an empty array.
        public static func stringEmptyReturnValue(_ value: String) -> Parser<I, Empty> {
            guard !value.isEmpty else {
                return Parser<I, Empty>.pure(Empty.empty)
            }

            let firstChar = value.first!
            return Parser<I, Character>.symbol(firstChar)
                .andR(string(String(value.dropFirst())))
                .andR(Parser<I, Empty>.pure(Empty.empty))
        }

        /// Returns a `Parser` which tests if the current element is a whitespace character.
        ///
        /// - Returns: A `Parser` which tests if the current element is a whitespace character.
        public static func whitespace() -> Parser<I, Character> {
            let characterSet = CharacterSet.whitespaces
            #if swift(>=4.2)
            return Parser<I, Character>.satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
            #else
            // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
            return Parser<I, Character>.satisfy(conditionName: "whitespace") {
                !$0.unicodeScalars.contains { !characterSet.contains($0) }
            }
            #endif
        }

        /// Returns a `Parser` which tests if the current element is a newline character.
        ///
        /// - Returns: A `Parser` which tests if the current element is a newline character.
        public static func newline() -> Parser<I, Character> {
            let characterSet = CharacterSet.newlines
            #if swift(>=4.2)
            return Parser<I, Character>.satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
            #else
            // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
            return Parser<I, Character>.satisfy(conditionName: "newline") {
                !$0.unicodeScalars.contains { !characterSet.contains($0) }
            }
            #endif
        }

        /// Returns a `Parser` which tests if the current element is a tab character.
        ///
        /// - Returns: A `Parser` which tests if the current element is a tab character.
        public static func tab() -> Parser<I, Character> {
            return Parser<I, Character>.symbol("\t")
        }
    }
}
