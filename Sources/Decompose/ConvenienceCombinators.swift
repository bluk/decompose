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

    /// Return a Parser which tests if the next value is a specific Character
    static func char<I>(_ value: Character) -> Parser<I, Character>
        where I.Element == Character {
        return satisfy { $0 == value }
    }

    /// Return a Parser which tests if the next value is a letter
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

    /// Return a Parser which tests if the next value is a digit
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

    /// Return a Parser which matches a given string
    static func string<I>(_ value: String) -> Parser<I, [Character]> where I.Element == Character {
        guard !value.isEmpty else {
            return Combinators.pure([])
        }

        return Parser { input in
            let firstCharParser: Parser<I, ([Character]) -> [Character]> = Parser { input in
                let firstChar = value.first!
                let result = Combinators.char(firstChar).parse(input)
                switch result.reply {
                case let .error(msgGenerator):
                    return Consumed(result.state, .error(msgGenerator))
                case let .success(value, advancedInput, msgGenerator):
                    let mergeFunc: ([Character]) -> [Character] = { [value] + $0 }
                    return Consumed(result.state, .success(mergeFunc, advancedInput, msgGenerator))
                }
            }

            return Combinators.apply(firstCharParser, Combinators.string(String(value.dropFirst()))).parse(input)
        }
    }

    /// Return a Parser which matches a given string. The value returned is an empty array if it succeeds.
    static func stringEmptyReturn<I>(_ value: String)
        -> Parser<I, [Character]> where I.Element == Character {
        guard !value.isEmpty else {
            return Combinators.pure([])
        }

        return Parser { input in
            let firstChar = value.first!
            return Combinators
                .then(Combinators.char(firstChar), to: { Combinators.stringEmptyReturn(String(value.dropFirst())) })
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
