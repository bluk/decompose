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
    static func letter<I>() -> Parser<I, Character>
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
    static func digit<I>() -> Parser<I, Character>
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

        let firstChar = value.first!
        return char(firstChar) *> string(String(value.dropFirst())) *> pure(value)
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

    /// Returns a `Parser` which invokes the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which invokes the `parser` parameter zero or more times.
    static func many<I, V>(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        let appendFunc: (V) -> ([V]) -> [V] = { element in { [element] + $0 } }
        return appendFunc <^> parser <*> wrap { many(parser) } <??> []
    }

    /// Returns a `Parser` which invokes the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
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

    /// Returns a `Parser` which discards the return value of the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter zero or more times.
    static func skipMany<I, V>(_ parser: Parser<I, V>) -> Parser<I, ()> {
        return skipMany1(parser) <|> pure(())
    }

    /// Returns a `Parser` which discards the return value of the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter one or more times.
    static func skipMany1<I, V>(_ parser: Parser<I, V>) -> Parser<I, ()> {
        return many1(parser) *> pure(())
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    /// use the second parameter.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    ///     - value: The value to return if the `parser` parameter is not successful.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    ///            use the second parameter.
    static func opt<I, V>(_ parser: Parser<I, V>, _ value: V) -> Parser<I, V> {
        return parser <|> pure(value)
    }

    /// Parses a value operand and an optional repeat of operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses a value operand and an optional repeat of operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    static func chainr<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return reduceOperations() <^> parserV <*> (many(chainrInternal(parserV, parserOp)) <??> [ { $0 } ])

//        return foldRight <^> parserX <*> many(chainrInternal(parserX, parserOp))
//        let f: Parser<I, (V) -> V> =
//            { op in { op($0) } } <^> parserOp <*> wrap { chainr(parserX, parserOp) }  <??> { $0 }
//        return  { xParam in { $0(xParam) } } <^> parserX <*> f
    }

    /// Parses a value operand and at least one operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses a value operand and at least one operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    static func chainr1<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return reduceOperations() <^> parserV <*> many1(chainrInternal(parserV, parserOp))
    }

    private static func chainrInternal<I, V>(
        _ parserV: Parser<I, V>,
        _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, (V) -> (V)> {
        return { operation in { yParam in { operation($0)(yParam) } } } <^> parserOp <*> parserV
    }

    /// Parses a value operand and an optional repeat of operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with left associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses a value operand and an optional repeat of operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with left associativity.
    static func chainl<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return reduceOperations() <^> parserV <*> (many(chainlInternal(parserV, parserOp)) <??> [ { $0 } ])
    }

    /// Parses a value operand and at least one operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with left associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses a value operand and at least one operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with left associativity.
    static func chainl1<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return reduceOperations() <^> parserV <*> many1(chainlInternal(parserV, parserOp))
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
}
