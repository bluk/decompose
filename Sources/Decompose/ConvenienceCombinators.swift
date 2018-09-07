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

    /// Returns a `Parser` which tests if the current element is a specific `Character`.
    ///
    /// - Parameters:
    ///     - value: The `Character` to test with.
    /// - Returns: A `Parser` which tests if the current element is a specific `Character`.
    static func char<I>(_ value: Character) -> Parser<I, Character>
        where I.Element == Character {
        return satisfy { $0 == value }
    }

    /// Returns a `Parser` which tests if the current element is a letter.
    ///
    /// - Returns: A `Parser` which tests if the current element is a letter.
    static func isLetter<I>() -> Parser<I, Character>
        where I.Element == Character {
        let characterSet = CharacterSet.letters
        #if swift(>=4.2)
        return satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
        #else
        // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
        return satisfy { !$0.unicodeScalars.contains { !characterSet.contains($0) } }
        #endif
    }

    /// Returns a `Parser` which tests if the current element is a digit.
    ///
    /// - Returns: A `Parser` which tests if the current element is a digit.
    static func isDigit<I>() -> Parser<I, Character>
        where I.Element == Character {
        let characterSet = CharacterSet.decimalDigits
        #if swift(>=4.2)
        return satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
        #else
        // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
        return satisfy { !$0.unicodeScalars.contains { !characterSet.contains($0) } }
        #endif
    }

    /// Returns a `Parser` which matches a given string.
    ///
    /// - Parameters:
    ///     - value: The `String` to test with.
    /// - Returns: A `Parser` which matches a given string.
    static func string<I>(_ value: String) -> Parser<I, String> where I.Element == Character {
        guard !value.isEmpty else {
            return Combinators.pure("")
        }

        return Parser { input in
            let firstChar = value.first!
            return Combinators
                .bind(Combinators.char(firstChar)) { firstCharValue in
                    Combinators.bind(Combinators.string(String(value.dropFirst()))) { restOfStringValues in
                        Combinators.pure(String([firstCharValue] + restOfStringValues))
                    }
                }
                .parse(input)
        }
    }

    /// Returns a `Parser` which matches a given string. If successful, the returned value is an empty array.
    ///
    /// - Parameters:
    ///     - value: The `String` to test with.
    /// - Returns: A `Parser` which matches a given string. If successful, the returned value is an empty array.
    static func stringEmptyReturnValue<I>(_ value: String)
        -> Parser<I, [Character]> where I.Element == Character {
        guard !value.isEmpty else {
            return Combinators.pure([])
        }

        return Parser { input in
            let firstChar = value.first!
            return Combinators
                .then(Combinators.char(firstChar)) {
                    Combinators.stringEmptyReturnValue(String(value.dropFirst()))
                }
                .parse(input)
        }
    }

    /// Returns a `Parser` which invokes the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke
    /// - Returns: A `Parser` which invokes the `parser` parameter one or more times.
    static func many1<I, V>(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return Parser { input in
            Combinators
                .bind(parser) { matchedValue in
                    Combinators.bind(many1(parser) <|> Combinators.pure([])) { optionalMatchedValues in
                        var returnValue: [V] = [matchedValue]
                        returnValue.append(contentsOf: optionalMatchedValues)
                        return Combinators.pure(returnValue)
                    }
                }
                .parse(input)
        }
    }
}
