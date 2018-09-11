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

// swiftlint:disable file_length

/// Convience methods to generate parsers
public extension Combinators {

    /// Returns a `Parser` which tests if the current element is a specific `Character`.
    ///
    /// - Parameters:
    ///     - value: The `Character` to test with.
    /// - Returns: A `Parser` which tests if the current element is a specific `Character`.
    static func char<I>(_ value: Character) -> Parser<I, Character>
        where I.Element == Character {
        return satisfy(conditionName: "\"\(value)\"") { $0 == value }
    }

    /// Returns a `Parser` which tests if the current element is a letter.
    ///
    /// - Returns: A `Parser` which tests if the current element is a letter.
    static func letter<I>() -> Parser<I, Character>
        where I.Element == Character {
        let characterSet = CharacterSet.letters
        #if swift(>=4.2)
        return satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
        #else
        // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
        return satisfy(conditionName: "letter") { !$0.unicodeScalars.contains { !characterSet.contains($0) } }
        #endif
    }

    /// Returns a `Parser` which tests if the current element is a digit.
    ///
    /// - Returns: A `Parser` which tests if the current element is a digit.
    static func digit<I>() -> Parser<I, Character>
        where I.Element == Character {
        let characterSet = CharacterSet.decimalDigits
        #if swift(>=4.2)
        return satisfy { $0.unicodeScalars.allSatisfy(characterSet.contains) }
        #else
        // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
        return satisfy(conditionName: "digit") { !$0.unicodeScalars.contains { !characterSet.contains($0) } }
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

        let firstChar = value.first!
        return symbol(firstChar) *> string(String(value.dropFirst())) *> pure(value)
    }

    /// Returns a `Parser` which matches a given string. If successful, the returned value is an empty array.
    ///
    /// - Parameters:
    ///     - value: The `String` to test with.
    /// - Returns: A `Parser` which matches a given string. If successful, the returned value is an empty array.
    static func stringEmptyReturnValue<I>(_ value: String)
        -> Parser<I, Empty> where I.Element == Character {
        guard !value.isEmpty else {
            return Combinators.pure(Empty.empty)
        }

        let firstChar = value.first!
        return symbol(firstChar) *> string(String(value.dropFirst())) *> pure(Empty.empty)
    }

    /// Returns a `Parser` which invokes the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which invokes the `parser` parameter zero or more times.
    static func many<I, V>(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return Parser(
            acceptsEmpty: true,
            firstSetSymbols: parser.computeFirstSetSymbols()
        ) { input, followSetSymbols in
            var results: [V] = []
            let followSetSymbolsMany = followSetSymbols.union(parser.computeFirstSetSymbols())
            var remainingInput = input
            repeat {
                if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                    if parser.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        let result = parser.apply(remainingInput, followSetSymbolsMany)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, value):
                            results.append(value)
                            remainingInput = remainingInput2
                            continue
                        }
                    }
                }

                return Result.success(remainingInput, results)
            } while true
        }
    }

    /// Returns a `Parser` which invokes the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which invokes the `parser` parameter one or more times.
    static func many1<I, V>(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return { first in { list in [first] + list } } <^> parser <*> many(parser)
    }

    /// Returns a `Parser` which discards the return value of the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter zero or more times.
    static func skipMany<I, V>(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return many(parser).map({ _ in Empty.empty })
    }

    /// Returns a `Parser` which discards the return value of the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter one or more times.
    static func skipMany1<I, V>(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return { first in { list in Empty.empty } } <^> parser <*> many(parser)
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    /// return nil.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    ///            return nil
    static func optionOptional<I, V>(_ parser: Parser<I, V>) -> Parser<I, V?> {
        return parser.map({ Optional($0) }) <|> pure(nil)
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds or not, return an `Empty.empty`.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds or not, return an `Empty.empty`.
    static func optional<I, V>(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return { _ in Empty.empty } <^> parser <|> pure(Empty.empty)
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    /// return the second paramater.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    ///            return nil
    static func option<I, V>(_ parser: Parser<I, V>, _ value: V) -> Parser<I, V> {
        return parser <|> pure(value)
    }

    /// Parses an optional operand with an optional repeat of operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    ///     - value: The value to use if the `parserV` fails.
    /// - Returns: A `Parser` which parses an optional operand and an optional repeat of operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    static func chainr<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V)
        -> Parser<I, V> {
        return chainr1(parserV, parserOp) <|> pure(value)
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero or more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    static func chainr1<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        let operatorParser: Parser<I, (V) -> V> = { operation in { operation($0) } }
            <^> parserOp <*> wrap { chainr1(parserV, parserOp) } <??> { $0 }
        return { xParam in { $0(xParam) } } <^> parserV <*> operatorParser
    }

    /// Parses an optional operand with an optional repeat of operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with left associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    ///     - value: The value to use if the `parserV` fails.
    /// - Returns: A `Parser` which parses an optional operand operand and an optional repeat of operator and operand
    ///            where the final parsed value is the calculation of the operands with the operators with left
    ///            associativity.
    static func chainl<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V)
        -> Parser<I, V> {
        return chainl1(parserV, parserOp) <|> pure(value)
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with left associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with left associativity.
    static func chainl1<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return reduceOperations() <^> parserV <*> (many(chainlInternal(parserV, parserOp)) <??> [ { $0 } ])
    }

    private static func chainlInternal<I, V>(
        _ parserV: Parser<I, V>,
        _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, (V) -> (V)> {
        return { operation in { yParam in { operation(yParam)($0) } } } <^> parserOp <*> parserV
    }

    private static func reduceOperations<V>() -> (V) -> ([(V) -> V]) -> V {
        return { firstValue in { operations in
            operations.reduce(firstValue, { resultValue, operation in operation(resultValue) }) }
        }
    }

    /// Parses zero or more values separated by a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by a separator and returns an array of the
    ///            parsed values.
    static func sepBy<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return sepBy1(parserV, parserSep) <|> pure([])
    }

    /// Parses one or more values separated by a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by a separator and returns an array of the
    ///            parsed values.
    static func sepBy1<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        let appendValuesFunc: (V) -> ([V]) -> [V] = { value in { list in [value] + list } }
        return appendValuesFunc <^> parserV <*> many(parserSep *> parserV)
    }

    /// Parses an open, value, and then a close, and returns the value.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserOpen: Parses an open value.
    ///     - parserClose: Parses a close value.
    /// - Returns: A `Parser` which parses an open, value, and then a close, and returns the value.
    static func between<I, O, V, C>(_ parserOpen: Parser<I, O>, _ parserV: Parser<I, V>, _ parserClose: Parser<I, C>)
        -> Parser<I, V> {
        return parserOpen *> parserV <* parserClose
    }

    /// Parses a value for `count` number of times and returns an array of the values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - count: The number of times to parse.
    /// - Returns: A `Parser` which parses a value for `count` number of times and returns an array of the values.
    static func count<I, V>(_ parser: Parser<I, V>, count: Int) -> Parser<I, [V]> {
        return Parser(
            acceptsEmpty: parser.computeAcceptsEmpty(),
            firstSetSymbols: parser.computeFirstSetSymbols()
        ) { input, followSetSymbols in
            var results: [V] = []
            var remainingInput = input
            for _ in 0..<count {
                if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                    if parser.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        let result = parser.apply(remainingInput, followSetSymbols)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, value):
                            results.append(value)
                            remainingInput = remainingInput2
                        }
                    }
                } else {
                    return Result<I, [V]>.failureUnavailableInput(remainingInput, parser.computeFirstSetSymbols())
                }
            }

            return Result.success(remainingInput, results)
        }
    }

    /// Parses zero or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    static func endBy<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return endBy1(parserV, parserSep) <|> pure([])
    }

    /// Parses one or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    static func endBy1<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return many1(parserV <* parserSep)
    }

    /// Parses zero or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    static func sepEndBy<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return sepEndBy1(parserV, parserSep) <|> pure([])
    }

    /// Parses one or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    static func sepEndBy1<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        let appendValuesFunc: (V) -> ([V]) -> [V] = { value in { list in [value] + list } }
        return appendValuesFunc <^> parserV <* optional(parserSep) <*> many(parserV <* parserSep)
    }

    /// Parses `parserV` zero or more times until `parserEnd` is encountered, and returns an array of the `parserV`
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserEnd: Parses an end value.
    /// - Returns: A `Parser` which parses `parserV` values zero or more times until `parserEnd` is encountered, and
    ///            returns an array of the `parserV` values.
    static func manyTill<I, V, V2>(_ parser: Parser<I, V>, _ parserEnd: Parser<I, V2>) -> Parser<I, [V]> {
        return Parser(
            acceptsEmpty: parser.computeAcceptsEmpty() || parserEnd.computeAcceptsEmpty(),
            firstSetSymbols: parser.computeFirstSetSymbols().union(parserEnd.computeFirstSetSymbols())
        ) { input, followSetSymbols in
            var results: [V] = []
            var remainingInput = input
            let followSetSymbolsManyTill = followSetSymbols
                .union(parser.computeFirstSetSymbols())
                .union(parserEnd.computeFirstSetSymbols())

            repeat {
                if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                    if parserEnd.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        let result = parserEnd.apply(remainingInput, followSetSymbolsManyTill)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, _):
                            return Result.success(remainingInput2, results)
                        }
                    } else if parser.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        let result = parser.apply(remainingInput, followSetSymbolsManyTill)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, value):
                            results.append(value)
                            remainingInput = remainingInput2
                        }
                    } else {
                        return Result<I, [V]>.failure(remainingInput, followSetSymbolsManyTill)
                    }
                } else {
                    return Result<I, [V]>.failureUnavailableInput(remainingInput, parserEnd.computeFirstSetSymbols())
                }
            } while true
        }
    }
}

// swiftlint:enable file_length
