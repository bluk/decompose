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
    static func char<Input1>(_ value: Character) -> Parser<Input1, Character>
        where Input1.Element == Character {
        return satisfy { $0 == value }
    }

    /// Return a Parser which tests if the next value is a letter
    static func isLetter<Input1>() -> Parser<Input1, Character>
        where Input1.Element == Character {
        let characterSet = CharacterSet.letters
        #if swift(>=4.2)
        return satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
        #else
        // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
        return satisfy { !$0.unicodeScalars.contains { !characterSet.contains($0) } }
        #endif
    }

    /// Return a Parser which tests if the next value is a digit
    static func isDigit<Input1>() -> Parser<Input1, Character>
        where Input1.Element == Character {
        let characterSet = CharacterSet.decimalDigits
        #if swift(>=4.2)
        return satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
        #else
        // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
        return satisfy { !$0.unicodeScalars.contains { !characterSet.contains($0) } }
        #endif
    }

    /// Return a Parser which matches a given string
    static func string<Input1>(_ value: String) -> Parser<Input1, [Character]> where Input1.Element == Character {
        guard !value.isEmpty else {
            let empty: [Character] = []
            return Combinators.returnValue(empty)
        }

        return Parser { input in
            let firstCharParser: Parser<Input1, ([Character]) -> [Character]> = Parser { input in
                let firstChar = value.first!
                let consumed = Combinators.char(firstChar).parse(input)
                switch consumed.reply {
                case let .error(error, remainingInput):
                    return Consumed(consumed.state, .error(error, remainingInput))
                case let .success(value, remainingInput):
                    let mergeFunc: ([Character]) -> [Character] = { [value] + $0 }
                    return Consumed(consumed.state, .success(mergeFunc, remainingInput))
                }
            }

            return Combinators.apply(firstCharParser, Combinators.string(String(value.dropFirst()))).parse(input)
        }
    }

    /// Return a Parser which matches a given string. The value returned is an empty array if it succeeds.
    static func stringEmptyReturn<Input1>(_ value: String)
        -> Parser<Input1, [Character]> where Input1.Element == Character {
        guard !value.isEmpty else {
            let empty: [Character] = []
            return Combinators.returnValue(empty)
        }

        return Parser { input in
            let firstChar = value.first!
            let firstCharParser: Parser<Input1, Character> = Combinators.char(firstChar)

            let func1: (Character) -> Parser<Input1, [Character]> = { _ in
                Combinators.stringEmptyReturn(String(value.dropFirst()))
            }

            return Combinators.bind(firstCharParser, to: func1).parse(input)
        }
    }
}
