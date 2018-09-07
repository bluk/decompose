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
            let empty: [Character] = []
            return Combinators.pure(empty)
        }

        return Parser { input in
            let firstCharParser: Parser<I, ([Character]) -> [Character]> = Parser { input in
                let firstChar = value.first!
                let result1 = Combinators.char(firstChar).parse(input)
                switch result1.reply {
                case let .error(error1):
                    return Consumed(result1.state, .error(error1))
                case let .success(value1, remainingInput1, error1):
                    let mergeFunc: ([Character]) -> [Character] = { [value1] + $0 }
                    return Consumed(result1.state, .success(mergeFunc, remainingInput1, error1))
                }
            }

            return Combinators.apply(firstCharParser, Combinators.string(String(value.dropFirst()))).parse(input)
        }
    }

    /// Return a Parser which matches a given string. The value returned is an empty array if it succeeds.
    static func stringEmptyReturn<I>(_ value: String)
        -> Parser<I, [Character]> where I.Element == Character {
        guard !value.isEmpty else {
            let empty: [Character] = []
            return Combinators.pure(empty)
        }

        return Parser { input in
            let firstChar = value.first!
            let firstCharParser: Parser<I, Character> = Combinators.char(firstChar)

            let func1: (Character) -> Parser<I, [Character]> = { _ in
                Combinators.stringEmptyReturn(String(value.dropFirst()))
            }

            return Combinators.bind(firstCharParser, to: func1).parse(input)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    /// Return a Parser which matches a given string. The value returned is an empty array if it succeeds.
    static func many1<I, V>(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return Parser { input in
            let result1 = parser.parse(input)
            switch result1.reply {
            case let .error(error1):
                return Consumed(result1.state, .error(error1))
            case let .success(value1, remainingInput1, error1):
                let result2 = (many1(parser) <|> pure([])).parse(remainingInput1)
                switch result1.state {
                case .consumed:
                    switch result2.reply {
                    case .error:
                        return Consumed(.consumed, .success([value1], remainingInput1, error1))
                    case let .success(value2, remainingInput2, error2):
                        return Consumed(.consumed, .success([value1] + value2, remainingInput2, error2))
                    }
                case .empty:
                    switch result2.state {
                    case .consumed:
                        switch result2.reply {
                        case let .success(value2, remainingInput2, error2):
                            return Consumed(.consumed, .success([value1] + value2, remainingInput2, error2))
                        case .error:
                            return Consumed(.consumed, .success([value1], remainingInput1, error1))
                        }
                    case .empty:
                        switch result2.reply {
                        case let .error(error2):
                            return mergeSuccess(
                                value: [value1],
                                input: remainingInput1,
                                error1: error1,
                                error2: error2
                            )
                        case let .success(value2, remainingInput2, error2):
                            return mergeSuccess(
                                value: [value1] + value2,
                                input: remainingInput2,
                                error1: error1,
                                error2: error2
                            )
                        }
                    }
                }
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
