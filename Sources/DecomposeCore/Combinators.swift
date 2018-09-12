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

/// Convenience methods to create and compose `Parser`s.
public enum Combinators {

    /// Instantiates a `Parser` which returns the value parameter and does not advanced the `Input`.
    ///
    /// - Parameters:
    ///     - value: The value to return from the `Parser`.
    /// - Returns: A `Parser` which returns the value parameter and does not advanced the `Input`.
    public static func pure<I, V>(_ value: V) -> Parser<I, V> {
        return Parser<I, V>.pure(value)
    }

    /// Returns a `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
    ///
    /// - Parameters:
    ///     - parser1: The first `Parser` to invoke the input with.
    ///     - parser2: The second `Parser` to invoke the input with if the first `Parser` fails.
    /// - Returns: A `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
    public static func or<I, V>(
        _ parser1: Parser<I, V>,
        _ parser2: Parser<I, V>) -> Parser<I, V> {
        return parser1.or(parser2)
    }

    /// Maps a `Parser`'s value using the function parameter.
    ///
    /// - Parameters:
    ///     - parser: The `Parser` to invoke the input with.
    ///     - func1: A function which will transform the `parser`'s return value into a new value.
    /// - Returns: A Parser which transforms the original value to a value using the function.
    public static func map<I, V1, V2>(
        _ parser: Parser<I, V1>,
        _ func1: @escaping (V1) -> V2) -> Parser<I, V2> {
        return parser.map(func1)
    }

    /// Sequentially invokes two Parsers while invoking the second parser's result into the first parser's function.
    ///
    /// - Parameters:
    ///     - parser1: The first `Parser` to invoke
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes the first `Parser` parameter, then the second `Parser` parameter and then
    ///           invokes the first `Parser`'s returned function value with the second `Parser`'s returned value.
    public static func apply<I, V1, V2>(
        _ parser1: Parser<I, (V1) -> V2>,
        _ parser2: Parser<I, V1>) -> Parser<I, V2> {
        return parser1.apply(parser2)
    }

    /// Returns a `Parser` which invokes the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which invokes the `parser` parameter zero or more times.
    public static func many<I, V>(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return parser.many()
    }

    /// Returns a `Parser` which invokes the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which invokes the `parser` parameter one or more times.
    public static func many1<I, V>(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return parser.many1()
    }

    /// Returns a `Parser` which discards the return value of the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter zero or more times.
    public static func skipMany<I, V>(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return parser.skipMany()
    }

    /// Returns a `Parser` which discards the return value of the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter one or more times.
    public static func skipMany1<I, V>(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return parser.skipMany1()
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    /// return nil.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    ///            return nil
    public static func optionOptional<I, V>(_ parser: Parser<I, V>) -> Parser<I, V?> {
        return parser.optionOptional()
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds or not, return an `Empty.empty`.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds or not, return an `Empty.empty`.
    public static func optional<I, V>(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return parser.optional()
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    /// return the second paramater.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    ///            return nil
    public static func option<I, V>(_ parser: Parser<I, V>, _ value: V) -> Parser<I, V> {
        return parser.option(value)
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
    public static func chainr<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V)
        -> Parser<I, V> {
            return parserV.chainr(parserOp, value)
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero or more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    public static func chainr1<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return parserV.chainr1(parserOp)
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
    public static func chainl<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V)
        -> Parser<I, V> {
            return parserV.chainl(parserOp, value)
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with left associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with left associativity.
    public static func chainl1<I, V>(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return parserV.chainl1(parserOp)
    }

    /// Parses zero or more values separated by a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by a separator and returns an array of the
    ///            parsed values.
    public static func sepBy<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepBy(parserSep)
    }

    /// Parses one or more values separated by a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by a separator and returns an array of the
    ///            parsed values.
    public static func sepBy1<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepBy1(parserSep)
    }

    /// Parses an open, value, and then a close, and returns the value.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserOpen: Parses an open value.
    ///     - parserClose: Parses a close value.
    /// - Returns: A `Parser` which parses an open, value, and then a close, and returns the value.
    public static func between<I, O, V, C>(
        _ parserOpen: Parser<I, O>,
        _ parserV: Parser<I, V>,
        _ parserClose: Parser<I, C>)
        -> Parser<I, V> {
            return parserV.between(parserOpen, parserClose)
    }

    /// Parses a value for `count` number of times and returns an array of the values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - count: The number of times to parse.
    /// - Returns: A `Parser` which parses a value for `count` number of times and returns an array of the values.
    public static func count<I, V>(_ parser: Parser<I, V>, _ count: Int) -> Parser<I, [V]> {
        return parser.count(count)
    }

    /// Parses zero or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    public static func endBy<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.endBy(parserSep)
    }

    /// Parses one or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    public static func endBy1<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.endBy1(parserSep)
    }

    /// Parses zero or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    public static func sepEndBy<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepEndBy(parserSep)
    }

    /// Parses one or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    public static func sepEndBy1<I, V, S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepEndBy1(parserSep)
    }

    /// Parses `parserV` zero or more times until `parserEnd` is encountered, and returns an array of the `parserV`
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserEnd: Parses an end value.
    /// - Returns: A `Parser` which parses `parserV` values zero or more times until `parserEnd` is encountered, and
    ///            returns an array of the `parserV` values.
    public static func manyTill<I, V, V2>(_ parser: Parser<I, V>, _ parserEnd: Parser<I, V2>) -> Parser<I, [V]> {
        return parser.manyTill(parserEnd)
    }

    /// Instantiates a `Parser` which accepts the symbol parameter and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts the symbol parameter and advances the `Input`.
    public static func symbol<I, S>(_ symbol: S) -> Parser<I, S> where S == I.Element {
        return Parser<I, S>.symbol(symbol)
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    /// Returns a `Parser` which passes an element to the `condition` function and succeeds if the `condition` returns
    /// true or fails if `condition` returns false.
    ///
    /// - Parameters:
    ///     - conditionName: The name of the condition.
    ///     - condition: A function which is passed in an element, and determines if the element meets some criteria.
    /// - Returns: A `Parser` which returns an element if it succeeds the condition.
    public static func satisfy<I, V>(conditionName: String, _ condition: @escaping (V) -> Bool)
        -> Parser<I, V> where I.Element == V {
        return Parser<I, V>.satisfy(conditionName: conditionName, condition)
    }

    /// Instantiates a `Parser` which only fails.
    ///
    /// - Returns: A `Parser` which only fails.
    public static func fail<I, V>() -> Parser<I, V> {
        return Parser<I, V>.fail()
    }

    /// Instantiates a `Parser` which succeeds if the end of the input is reached.
    ///
    /// - Returns: A `Parser` which succeeds if the end of the input is reached.
    public static func endOfInput<I>() -> Parser<I, Empty> {
        return Parser<I, Empty>.endOfInput()
    }

    /// Accepts any element and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts any element and advances the `Input`.
    public static func any<I, V>() -> Parser<I, V> where V == I.Element {
        return Parser<I, V>.any()
    }

    /// Accepts any of the elements in the set and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts any element and advances the `Input`.
    public static func oneOf<I, V>(_ elementSet: Set<V>) -> Parser<I, V> where V == I.Element {
        return Parser<I, V>.oneOf(elementSet)
    }
}
