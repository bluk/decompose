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

// swiftlint:disable file_length

/// A value type for the `apply` function.
public struct Parser<I, V> where I: Input, I.Element: Comparable, I.Element: Hashable {

    /// Initializes a parser.
    ///
    /// - Parameters:
    ///     - computeAcceptsEmpty: A function to lazily compute if the `Parser` accepts an empty input.
    ///     - firstSetSymbols: A function to lazily compute the first set of accepted symbols.
    ///     - parse: A function to parse the `Input`
    public init(acceptsEmpty computeAcceptsEmpty: @autoclosure @escaping () -> Bool,
                firstSetSymbols computeFirstSetSymbols: @autoclosure @escaping () -> Set<Symbol<I.Element>>,
                parse: @escaping (I, Set<Symbol<I.Element>>) -> Result<I, V>) {
        self.computeAcceptsEmpty = computeAcceptsEmpty
        self.computeFirstSetSymbols = computeFirstSetSymbols
        self.computeParse = parse
    }

    /// Returns true if this `Parser` accepts an empty input.
    public let computeAcceptsEmpty: () -> Bool

    /// Returns the first set of symbols which can be accepted as input.
    public let computeFirstSetSymbols: () -> Set<Symbol<I.Element>>

    /// A function which takes an `Input` and a set of follow symbols and returns a type which either a parsed value
    /// or an error message.
    public let computeParse: (I, Set<Symbol<I.Element>>) -> Result<I, V>

    /// A method to run the parser with an `Input`.
    public func parse(_ input: I) -> Result<I, V> {
        let parserAndEndOfInput = self.andL(Parser.endOfInput())
        if computeAcceptsEmpty() {
            return parserAndEndOfInput.computeParse(input, [Symbol.empty])
        } else if !input.isAvailable {
            return Result.failureUnavailableInput(input, computeFirstSetSymbols())
        } else if let current = input.current(), computeFirstSetSymbols().contains(where: { $0.matches(current) }) {
            return parserAndEndOfInput.computeParse(input, [Symbol.empty])
        } else {
            return Result.failure(input, computeFirstSetSymbols())
        }
    }
}

/// Convenience methods for `Parser`.
public extension Parser {

    /// Instantiates a `Parser` which returns the value parameter and does not advanced the `Input`.
    ///
    /// - Parameters:
    ///     - value: The value to return from the `Parser`.
    /// - Returns: A `Parser` which returns the value parameter and does not advanced the `Input`.
    public static func pure(_ value: V) -> Parser<I, V> {
        return Parser<I, V>(acceptsEmpty: true, firstSetSymbols: [Symbol.empty]) { input, _ in
            Result.success(input, value)
        }
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

    /// Sequentially invokes this `Parser`, then the parameter argument, and finally invokes the second parser's result
    /// into this parser's function.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes this `Parser`, then the parameter argument, and finally invokes the second
    ///            parser's result into this parser's function.
    public func apply<V2, V3>(_ parser2: Parser<I, V2>) -> Parser<I, V3> where V == (V2) -> V3 {
        return Parser<I, V3>(
            acceptsEmpty: self.computeAcceptsEmpty() && parser2.computeAcceptsEmpty(),
            firstSetSymbols: {
                let symbols = self.computeFirstSetSymbols()
                if self.computeAcceptsEmpty() {
                    return symbols.union(parser2.computeFirstSetSymbols())
                }
                return symbols
            }(),
            parse: { input, followSetSymbols in
                let followSetSymbolsForFunction: Set<Symbol<I.Element>> = {
                    let symbols = parser2.computeFirstSetSymbols()
                    if parser2.computeAcceptsEmpty() {
                        return symbols.union(followSetSymbols)
                    }
                    return symbols
                }()

                let functionReply = self.computeParse(input, followSetSymbolsForFunction)
                switch functionReply {
                case let .failure(remainingInput, symbols):
                    return Result<I, V3>.failure(remainingInput, symbols)
                case let .failureUnavailableInput(remainingInput, symbols):
                    return Result<I, V3>.failureUnavailableInput(remainingInput, symbols)
                case let .success(remainingInput, value):
                    if !parser2.computeAcceptsEmpty() {
                        if !remainingInput.isAvailable {
                            return Result.failureUnavailableInput(remainingInput, parser2.computeFirstSetSymbols())
                        }

                        #if swift(>=4.2)
                        if parser2.computeFirstSetSymbols().allSatisfy({ !$0.matches(remainingInput.current()!) }) {
                        return Result.failure(remainingInput, parser2.computeFirstSetSymbols())
                        }
                        #else
                        // https://github.com/apple/swift-evolution/blob/master/proposals/0207-containsOnly.md
                        if !(parser2.computeFirstSetSymbols().contains { $0.matches(remainingInput.current()!) }) {
                            return Result.failure(remainingInput, parser2.computeFirstSetSymbols())
                        }
                        #endif
                    }
                    return parser2.computeParse(remainingInput, followSetSymbols).map(value)
                }
            })
    }

    /// Maps a `Parser`'s value using the function parameter.
    ///
    /// - Parameters:
    ///     - parser: The `Parser` to invoke the input with.
    ///     - func1: A function which will transform the `parser`'s return value into a new value.
    /// - Returns: A Parser which transforms the original value to a value using the function.
    public static func map<V2>(_ parser: Parser<I, V>, _ func1: @escaping (V) -> V2) -> Parser<I, V2> {
        return parser.map(func1)
    }

    /// Maps this `Parser`'s value using the function parameter.
    ///
    /// - Parameters:
    ///     - func1: A function which will transform the `parser`'s return value into a new value.
    /// - Returns: A Parser which transforms the original value to a value using the function.
    public func map<V2>(_ func1: @escaping (V) -> V2) -> Parser<I, V2> {
        return Parser<I, V2>(
            acceptsEmpty: self.computeAcceptsEmpty(),
            firstSetSymbols: self.computeFirstSetSymbols()) {
                self.computeParse($0, $1).map(func1)
        }
    }

    /// Returns a `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
    ///
    /// - Parameters:
    ///     - parser1: The first `Parser` to invoke the input with.
    ///     - parser2: The second `Parser` to invoke the input with if the first `Parser` fails.
    /// - Returns: A `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
    public static func or(_ parser1: Parser<I, V>, _ parser2: Parser<I, V>) -> Parser<I, V> {
        return parser1.or(parser2)
    }

    /// Returns a `Parser` which invokes this `Parser`, and if it fails, invokes the second `Parser`.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke the input with if this `Parser` fails.
    /// - Returns: A `Parser` which invokes this `Parser`, and if it fails, invokes the second `Parser`.
    public func or(_ parser2: Parser<I, V>) -> Parser<I, V> {
        return Parser<I, V>(
            acceptsEmpty: self.computeAcceptsEmpty() || parser2.computeAcceptsEmpty(),
            firstSetSymbols: self.computeFirstSetSymbols().union(parser2.computeFirstSetSymbols())
        ) { input, followSetSymbols in
            if let currentValue = input.current(), input.isAvailable {
                if self.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                    return self.computeParse(input, followSetSymbols)
                }

                if parser2.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                    return parser2.computeParse(input, followSetSymbols)
                }

                if followSetSymbols.contains(where: { $0.matches(currentValue) }) {
                    if self.computeAcceptsEmpty() {
                        return self.computeParse(input, followSetSymbols)
                    }

                    if parser2.computeAcceptsEmpty() {
                        return parser2.computeParse(input, followSetSymbols)
                    }
                }

                return Result.failure(
                    input,
                    self.computeFirstSetSymbols().union(parser2.computeFirstSetSymbols()).union(followSetSymbols)
                )
            } else {
                if self.computeAcceptsEmpty() {
                    return self.computeParse(input, followSetSymbols)
                } else if parser2.computeAcceptsEmpty() {
                    return parser2.computeParse(input, followSetSymbols)
                } else {
                    return Result.failureUnavailableInput(
                        input,
                        self.computeFirstSetSymbols().union(parser2.computeFirstSetSymbols()).union(followSetSymbols)
                    )
                }
            }
        }
    }

    /// Sequentially invokes a `Parser` in the array until one of them succeeds or all of them fail.
    ///
    /// - Parameters:
    ///     - parsers: The array of `Parser`s to attempt.
    /// - Returns: A `Parser` which sequentially invokes a `Parser` in the array until one of them succeeds or all
    ///            of them fail.
    public static func choice(_ parsers: [Parser<I, V>]) -> Parser<I, V> {
        guard let firstParser = parsers.first else {
            return Parser.fail()
        }

        return firstParser.choice(Array(parsers.dropFirst()))
    }

    // swiftlint:disable cyclomatic_complexity

    /// Returns a `Parser` which invokes this `Parser`, and if it fails, attempts the next `Parser` in the array.
    ///
    /// - Parameters:
    ///     - parsers: The `Parser`s to attempt if this `Parser` fails.
    /// - Returns: A `Parser` which invokes this `Parser`, and if it fails, attempts the next `Parser` in the array.
    public func choice(_ parsers: [Parser<I, V>]) -> Parser<I, V> {
        return Parser<I, V>(
            acceptsEmpty: parsers.reduce(self.computeAcceptsEmpty(), { result, parser in
                result || parser.computeAcceptsEmpty()
            }),
            firstSetSymbols: parsers.reduce(self.computeFirstSetSymbols(), { result, parser in
                result.union(parser.computeFirstSetSymbols())
            })
        ) { input, followSetSymbols in
            if let currentValue = input.current(), input.isAvailable {
                if self.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                    return self.computeParse(input, followSetSymbols)
                }

                for parser in parsers {
                    if parser.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        return parser.computeParse(input, followSetSymbols)
                    }
                }

                if followSetSymbols.contains(where: { $0.matches(currentValue) }) {
                    if self.computeAcceptsEmpty() {
                        return self.computeParse(input, followSetSymbols)
                    }

                    for parser in parsers {
                        if parser.computeAcceptsEmpty() {
                            return parser.computeParse(input, followSetSymbols)
                        }
                    }
                }

                let possibleSymbols = parsers.reduce(self.computeFirstSetSymbols(), { result, parser in
                    result.union(parser.computeFirstSetSymbols())
                })
                return Result.failure(input, possibleSymbols.union(followSetSymbols))
            } else {
                if self.computeAcceptsEmpty() {
                    return self.computeParse(input, followSetSymbols)
                } else {
                    for parser in parsers {
                        if parser.computeAcceptsEmpty() {
                            return parser.computeParse(input, followSetSymbols)
                        }
                    }
                }

                let possibleSymbols = parsers.reduce(self.computeFirstSetSymbols(), { result, parser in
                    result.union(parser.computeFirstSetSymbols())
                })
                return Result.failureUnavailableInput(input, possibleSymbols.union(followSetSymbols))
            }
        }
    }

    // swiftlint:enable cyclomatic_complexity

    /// Sequentially invokes this `Parser` and then the `Parser` argument while ignoring the second value.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes this `Parser`, then the second `Parser` parameter and then
    ///            returns this `Parser`'s returned value.
    public func andL<V2>(_ parser2: Parser<I, V2>) -> Parser<I, V> {
        return Parser<I, V>.apply(map({ first in { _ in first } }), parser2)
    }

    /// Sequentially invokes this `Parser` and then the `Parser` argument while ignoring the first value.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes this `Parser`, then the second `Parser` parameter and then
    ///            returns the second `Parser`'s returned value.
    public func andR<V2>(_ parser2: Parser<I, V2>) -> Parser<I, V2> {
        return Parser<I, V2>.apply(map({ _ in { second in second } }), parser2)
    }

    /// Returns a `Parser` which invokes the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which invokes the `parser` parameter zero or more times.
    public static func many(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return parser.many()
    }

    /// Returns a `Parser` which invokes this `Parser` zero or more times.
    ///
    /// - Returns: A `Parser` which invokes this `Parser` zero or more times.
    public func many() -> Parser<I, [V]> {
        return Parser<I, [V]>(
            acceptsEmpty: true,
            firstSetSymbols: self.computeFirstSetSymbols()
        ) { input, followSetSymbols in
            var results: [V] = []
            let followSetSymbolsMany = followSetSymbols.union(self.computeFirstSetSymbols())
            var remainingInput = input
            repeat {
                if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                    if self.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        let result = self.computeParse(remainingInput, followSetSymbolsMany)
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
    public static func many1(_ parser: Parser<I, V>) -> Parser<I, [V]> {
        return parser.many1()
    }

    /// Returns a `Parser` which invokes this `Parser` one or more times.
    ///
    /// - Returns: A `Parser` which invokes this `Parser` one or more times.
    public func many1() -> Parser<I, [V]> {
        return self.map({ first in { list in [first] + list } }).apply(self.many())
    }

    /// Returns a `Parser` which discards the return value of the `parser` parameter zero or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter zero or more times.
    public static func skipMany(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return parser.skipMany()
    }

    /// Returns a `Parser` which discards the return value of this `parser` zero or more times.
    ///
    /// - Returns: A `Parser` which discards the return value of this `parser` zero or more times.
    public func skipMany() -> Parser<I, Empty> {
        return self.many().map({ _ in Empty.empty })
    }

    /// Returns a `Parser` which discards the return value of the `parser` parameter one or more times.
    ///
    /// - Parameters:
    ///     - parser: The Parser to invoke.
    /// - Returns: A `Parser` which discards the return value of the `parser` parameter one or more times.
    public static func skipMany1(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return parser.skipMany1()
    }

    /// Returns a `Parser` which discards the return value of this `parser` one or more times.
    ///
    /// - Returns: A `Parser` which discards the return value of this `parser` oneor more times.
    public func skipMany1() -> Parser<I, Empty> {
        return self.map({ _ in { _ in Empty.empty } }).apply(self.many())
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    /// return nil.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    ///            return nil
    public static func optionOptional(_ parser: Parser<I, V>) -> Parser<I, V?> {
        return parser.optionOptional()
    }

    /// Returns a `Parser` which if it succeeds, return the value, but if it fails, return nil.
    ///
    /// - Returns: A `Parser` which if it succeeds, return the value, but if it fails, return nil.
    public func optionOptional() -> Parser<I, V?> {
        return map({ Optional($0) }).or(Parser<I, V?>.pure(nil))
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds or not, return an `Empty.empty`.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds or not, return an `Empty.empty`.
    public static func optional(_ parser: Parser<I, V>) -> Parser<I, Empty> {
        return parser.optional()
    }

    /// Returns a `Parser` which if it succeeds or not, return an `Empty.empty`.
    ///
    /// - Returns: A `Parser` which if it succeeds or not, return an `Empty.empty`.
    public func optional() -> Parser<I, Empty> {
        return self.map({ _ in Empty.empty }).or(Parser<I, Empty>.pure(Empty.empty))
    }

    /// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    /// return the second paramater.
    ///
    /// - Parameters:
    ///     - parser: The Parser to attempt.
    ///     - value: The value to return if the `Parser` does not succeed.
    /// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
    ///            return nil
    public static func option(_ parser: Parser<I, V>, _ value: V) -> Parser<I, V> {
        return parser.option(value)
    }

    /// Returns a `Parser` which if it succeeds, return the value, but if it fails, return the paramater.
    ///
    /// - Parameters:
    ///     - value: The value to return if the `Parser` does not succeed.
    /// - Returns: A `Parser` which attempts if it succeeds, return the value, but if it fails, return the paramater.
    public func option(_ value: V) -> Parser<I, V> {
        return self.or(Parser.pure(value))
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
    public static func chainr(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V)
        -> Parser<I, V> {
        return parserV.chainr(parserOp, value)
    }

    /// Parses an optional operand with an optional repeat of operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserOp: The operator Parser.
    ///     - value: The value to use if the `parserV` fails.
    /// - Returns: A `Parser` which parses an optional operand and an optional repeat of operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    public func chainr(_ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V) -> Parser<I, V> {
        return self.chainr1(parserOp).or(Parser.pure(value))
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero or more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    public static func chainr1(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return parserV.chainr1(parserOp)
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with right associativity.
    ///
    /// - Parameters:
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero or more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with right associativity.
    public func chainr1(_ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        let operatorParser: Parser<I, (V) -> V> = parserOp
            .map({ operation in { operation($0) } })
            .apply(Parser.wrap({ self.chainr1(parserOp) }))
            .option({ $0 })
        return self.map({ xParam in { $0(xParam) } }).apply(operatorParser)
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
    public static func chainl(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V)
        -> Parser<I, V> {
        return parserV.chainl(parserOp, value)
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
    public func chainl(_ parserOp: Parser<I, (V) -> (V) -> V>, _ value: V) -> Parser<I, V> {
        return self.chainl1(parserOp).or(Parser.pure(value))
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with left associativity.
    ///
    /// - Parameters:
    ///     - parserV: The value operand Parser.
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with left associativity.
    public static func chainl1(_ parserV: Parser<I, V>, _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return parserV.chainl1(parserOp)
    }

    /// Parses a value operand and zero or more operator and operand where the final parsed value is the
    /// calculation of the operands with the operators with left associativity.
    ///
    /// - Parameters:
    ///     - parserOp: The operator Parser.
    /// - Returns: A `Parser` which parses an operand and zero more operator and operand where the
    ///            final parsed value is the calculation of the operands with the operators with left associativity.
    public func chainl1(_ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, V> {
        return self
            .map(Parser.reduceOperations())
            .apply((Parser.chainlInternal(self, parserOp).many().option([ { $0 } ])))
    }

    private static func chainlInternal<I, V>(
        _ parserV: Parser<I, V>,
        _ parserOp: Parser<I, (V) -> (V) -> V>) -> Parser<I, (V) -> (V)> {
        return parserOp.map({ operation in { yParam in { operation(yParam)($0) } } }).apply(parserV)
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
    public static func sepBy<S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepBy(parserSep)
    }

    /// Parses zero or more values separated by a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by a separator and returns an array of the
    ///            parsed values.
    public func sepBy<S>(_ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return self.sepBy1(parserSep).or(Parser<I, [V]>.pure([]))
    }

    /// Parses one or more values separated by a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by a separator and returns an array of the
    ///            parsed values.
    public static func sepBy1<S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepBy1(parserSep)
    }

    /// Parses one or more values separated by a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by a separator and returns an array of the
    ///            parsed values.
    public func sepBy1<S>(_ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        let appendValuesFunc: (V) -> ([V]) -> [V] = { value in { list in [value] + list } }
        return self.map(appendValuesFunc).apply((parserSep.andR(self)).many())
    }

    /// Parses an open, value, and then a close, and returns the value.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserOpen: Parses an open value.
    ///     - parserClose: Parses a close value.
    /// - Returns: A `Parser` which parses an open, value, and then a close, and returns the value.
    public static func between<O, C>(
        _ parserOpen: Parser<I, O>,
        _ parserV: Parser<I, V>,
        _ parserClose: Parser<I, C>)
        -> Parser<I, V> {
        return parserV.between(parserOpen, parserClose)
    }

    /// Parses an open, value, and then a close, and returns the value.
    ///
    /// - Parameters:
    ///     - parserOpen: Parses an open value.
    ///     - parserClose: Parses a close value.
    /// - Returns: A `Parser` which parses an open, value, and then a close, and returns the value.
    public func between<O, C>(_ parserOpen: Parser<I, O>, _ parserClose: Parser<I, C>) -> Parser<I, V> {
        return parserOpen.andR(self).andL(parserClose)
    }

    /// Parses a value for `count` number of times and returns an array of the values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - count: The number of times to parse.
    /// - Returns: A `Parser` which parses a value for `count` number of times and returns an array of the values.
    public static func count(_ parser: Parser<I, V>, _ count: Int) -> Parser<I, [V]> {
        return parser.count(count)
    }

    // swiftlint:disable cyclomatic_complexity function_body_length

    /// Parses a value for `count` number of times and returns an array of the values.
    ///
    /// - Parameters:
    ///     - count: The number of times to parse.
    /// - Returns: A `Parser` which parses a value for `count` number of times and returns an array of the values.
    public func count(_ count: Int) -> Parser<I, [V]> {
        return Parser<I, [V]>(
            acceptsEmpty: self.computeAcceptsEmpty(),
            firstSetSymbols: self.computeFirstSetSymbols()
        ) { input, followSetSymbols in
            var results: [V] = []
            var remainingInput = input
            for _ in 0..<count {
                if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                    if self.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        let result = self.computeParse(remainingInput, followSetSymbols)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, value):
                            results.append(value)
                            remainingInput = remainingInput2
                        }
                    } else if self.computeAcceptsEmpty() {
                        let result = self.computeParse(remainingInput, followSetSymbols)
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
                        return Result.failure(remainingInput, self.computeFirstSetSymbols())
                    }
                } else if self.computeAcceptsEmpty() {
                    let result = self.computeParse(remainingInput, followSetSymbols)
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
                    return Result<I, [V]>.failureUnavailableInput(remainingInput, self.computeFirstSetSymbols())
                }
            }

            return Result.success(remainingInput, results)
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    /// Parses zero or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    public static func endBy<S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.endBy(parserSep)
    }

    /// Parses zero or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    public func endBy<S>(_ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return self.endBy1(parserSep).or(Parser<I, [V]>.pure([]))
    }

    /// Parses one or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    public static func endBy1<S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.endBy1(parserSep)
    }

    /// Parses one or more values separated by and ends with a separator and returns an array of the parsed values.
    ///
    /// - Parameters:
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and ends with a separator and returns an
    ///            array of the parsed values.
    public func endBy1<S>(_ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return (self.andL(parserSep)).many1()
    }

    /// Parses zero or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    public static func sepEndBy<S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepEndBy(parserSep)
    }

    /// Parses zero or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses zero or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    public func sepEndBy<S>(_ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return self.sepEndBy1(parserSep).or(Parser<I, [V]>.pure([]))
    }

    /// Parses one or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserV: Parses a value.
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    public static func sepEndBy1<S>(_ parserV: Parser<I, V>, _ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        return parserV.sepEndBy1(parserSep)
    }

    /// Parses one or more values separated by and optionally ends with a separator and returns an array of the parsed
    /// values.
    ///
    /// - Parameters:
    ///     - parserSep: Parses a separator.
    /// - Returns: A `Parser` which parses one or more values separated by and optionally ends with a separator and
    ///            returns an array of the parsed values.
    public func sepEndBy1<S>(_ parserSep: Parser<I, S>) -> Parser<I, [V]> {
        let appendValuesFunc: (V) -> ([V]) -> [V] = { value in { list in [value] + list } }
        return self.map(appendValuesFunc).andL(parserSep.optional()).apply((self.andL(parserSep)).many())
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

    // swiftlint:disable cyclomatic_complexity function_body_length

    /// Parses `parserV` zero or more times until `parserEnd` is encountered, and returns an array of the `parserV`
    /// values.
    ///
    /// - Parameters:
    ///     - parserEnd: Parses an end value.
    /// - Returns: A `Parser` which parses `parserV` values zero or more times until `parserEnd` is encountered, and
    ///            returns an array of the `parserV` values.
    public func manyTill<V2>(_ parserEnd: Parser<I, V2>) -> Parser<I, [V]> {
        return Parser<I, [V]>(
            acceptsEmpty: self.computeAcceptsEmpty() || parserEnd.computeAcceptsEmpty(),
            firstSetSymbols: self.computeFirstSetSymbols().union(parserEnd.computeFirstSetSymbols())
        ) { input, followSetSymbols in
            var results: [V] = []
            var remainingInput = input
            let followSetSymbolsManyTill = followSetSymbols
                .union(self.computeFirstSetSymbols())
                .union(parserEnd.computeFirstSetSymbols())

            repeat {
                if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                    if parserEnd.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) ||
                        parserEnd.computeAcceptsEmpty() {
                        let result = parserEnd.computeParse(remainingInput, followSetSymbolsManyTill)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, _):
                            return Result.success(remainingInput2, results)
                        }
                    } else if self.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                        let result = self.computeParse(remainingInput, followSetSymbolsManyTill)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, value):
                            results.append(value)
                            remainingInput = remainingInput2
                        }
                    } else if self.computeAcceptsEmpty() {
                        // Should not occur
                        assert(false, "Parser should not accept empty in manyTill.")
                        return Result<I, [V]>.failure(remainingInput, followSetSymbolsManyTill)
                    } else {
                        return Result<I, [V]>.failure(remainingInput, followSetSymbolsManyTill)
                    }
                } else if parserEnd.computeAcceptsEmpty() {
                    let result = parserEnd.computeParse(remainingInput, followSetSymbolsManyTill)
                    switch result {
                    case let .failure(remainingInput, symbols):
                        return Result<I, [V]>.failure(remainingInput, symbols)
                    case let .failureUnavailableInput(remainingInput, symbols):
                        return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                    case let .success(remainingInput2, _):
                        return Result.success(remainingInput2, results)
                    }
                } else if self.computeAcceptsEmpty() {
                    // Should not occur
                    assert(false, "Parser should not accept empty in manyTill.")
                    return Result<I, [V]>.failure(remainingInput, followSetSymbolsManyTill)
                } else {
                    return Result<I, [V]>.failureUnavailableInput(remainingInput, parserEnd.computeFirstSetSymbols())
                }
            } while true
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    /// Instantiates a `Parser` which constructs its real parser via a function.
    ///
    /// Useful in instances of recursion where the recursive call can be wrapped in a closure.
    ///
    /// - Parameters:
    ///     - func1: A function which returns a parser.
    /// - Returns: A `Parser` which calls the returned parser from `func1`.
    public static func wrap<I, V>(_ func1: @escaping () -> Parser<I, V>) -> Parser<I, V> {
        return Parser<I, V>(
            acceptsEmpty: func1().computeAcceptsEmpty(),
            firstSetSymbols: func1().computeFirstSetSymbols()
        ) {
            func1().computeParse($0, $1)
        }
    }

    /// Instantiates a `Parser` which accepts the symbol parameter and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts the symbol parameter and advances the `Input`.
    public static func symbol(_ symbol: I.Element) -> Parser<I, I.Element> {
        return Parser.value(symbol)
    }

    /// Instantiates a `Parser` which accepts the element parameter and advances the `Input`.
    ///
    /// - Parameters:
    ///     - element: The element to expect.
    /// - Returns: A `Parser` which accepts the  element parameter and advances the `Input`.
    public static func value(_ element: I.Element) -> Parser<I, I.Element> {
        return Parser.value(element: element, value: element)
    }

    /// Instantiates a `Parser` which accepts the symbol parameter and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts the symbol parameter and advances the `Input`.
    public static func value<I, V>(element: I.Element, value: V) -> Parser<I, V> {
        return Parser<I, V>(acceptsEmpty: false, firstSetSymbols: [Symbol.value(element)]) { input, _ in
            Result.success(input.advanced(), value)
        }
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
            return Parser<I, V>(
                acceptsEmpty: false,
                firstSetSymbols: [Symbol.predicate(name: conditionName, condition)]
            ) { input, _ in
                Result.success(input.advanced(), input.current()!)
            }
    }

    /// Instantiates a `Parser` which only fails.
    ///
    /// - Returns: A `Parser` which only fails.
    public static func fail<I, V>() -> Parser<I, V> {
        return Parser<I, V>(
            acceptsEmpty: true,
            firstSetSymbols: [Symbol.empty]
        ) { input, _ in
            Result.failure(input, [Symbol<I.Element>.empty])
        }
    }

    /// Instantiates a `Parser` which succeeds if the end of the input is reached.
    ///
    /// - Returns: A `Parser` which succeeds if the end of the input is reached.
    public static func endOfInput<I>() -> Parser<I, Empty> {
        return Parser<I, Empty>(acceptsEmpty: true, firstSetSymbols: [Symbol.empty]) { input, _ in
            if !input.isAvailable {
                return Result.success(input, Empty.empty)
            }
            return Result.failure(input, [Symbol.empty])
        }
    }

    /// Accepts any element and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts any element and advances the `Input`.
    public static func any<I, V>() -> Parser<I, V> where V == I.Element {
        return Parser<I, V>(acceptsEmpty: false, firstSetSymbols: [Symbol.all]) { input, followSetSymbols in
            if let currentValue = input.current(), input.isAvailable {
                return Result.success(input.advanced(), currentValue)
            } else {
                return Result<I, V>.failureUnavailableInput(input, followSetSymbols)
            }
        }
    }

    /// Accepts any of the elements in the set and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts any element in the set and advances the `Input`.
    public static func oneOf<I, V>(_ elementSet: Set<V>) -> Parser<I, V> where V == I.Element {
        return Parser<I, V>(
            acceptsEmpty: false,
            firstSetSymbols: Set(elementSet.map { Symbol.value($0) })) { input, followSetSymbols in
            if input.isAvailable {
                if let currentValue = input.current(), elementSet.contains(currentValue) {
                    return Result.success(input.advanced(), currentValue)
                }

                return Result.failure(input, followSetSymbols)
            } else {
                return Result<I, V>.failureUnavailableInput(input, followSetSymbols)
            }
        }
    }

    /// Accepts any element but the elements in the set and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts any element but elements in the set and advances the `Input`.
    public static func noneOf<I, V>(_ elementSet: Set<V>) -> Parser<I, V> where V == I.Element {
        return Parser<I, V>(
            acceptsEmpty: false,
            firstSetSymbols: {
                let noneOfString = elementSet.sorted().map { "\($0)" }.joined(separator: ", ")
                return [Symbol.predicate(name: "none of \(noneOfString)", { !elementSet.contains($0) })]
            }(),
            parse: { input, followSetSymbols in
                if input.isAvailable {
                    if let currentValue = input.current(), !elementSet.contains(currentValue) {
                        return Result.success(input.advanced(), currentValue)
                    }

                    return Result.failure(input, followSetSymbols)
                } else {
                    return Result<I, V>.failureUnavailableInput(input, followSetSymbols)
                }
            })
    }

    // swiftlint:disable cyclomatic_complexity function_body_length

    /// Returns a `Parser` which iterates over the array parameter of `Parser`s and collects their results in
    /// an array.
    ///
    /// - Parameters:
    ///     - parsers: The parsers to invoke in order.
    /// - Returns: A`Parser` which iterates over the array parameter of `Parser`s and collects their results in an
    ///            array.
    public static func sequence<I, V>(_ parsers: [Parser<I, V>]) -> Parser<I, [V]> {
        return Parser<I, [V]>(
            acceptsEmpty: {
                if let firstParser = parsers.first {
                    return firstParser.computeAcceptsEmpty()
                }
                return true
            }(),
            firstSetSymbols: {
                if let firstParser = parsers.first {
                    return firstParser.computeFirstSetSymbols()
                }
                return [Symbol.empty]
            }(),
            parse: { input, followSetSymbols in
                var results: [V] = []
                var remainingInput = input

                for parser in parsers {
                    if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                        if parser.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                            switch parser.computeParse(remainingInput, followSetSymbols) {
                            case let .success(remainingSuccessInput, value):
                                remainingInput = remainingSuccessInput
                                results.append(value)
                            case let .failure(remainingInput, expectedSymbols):
                                return Result.failure(remainingInput, expectedSymbols)
                            case let .failureUnavailableInput(remainingInput, expectedSymbols):
                                return Result.failureUnavailableInput(remainingInput, expectedSymbols)
                            }
                        } else if parser.computeAcceptsEmpty() {
                            let result = parser.computeParse(remainingInput, followSetSymbols)
                            switch result {
                            case let .failure(remainingInput, symbols):
                                return Result<I, [V]>.failure(remainingInput, symbols)
                            case let .failureUnavailableInput(remainingInput, symbols):
                                return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                            case let .success(remainingInput2, value):
                                remainingInput = remainingInput2
                                results.append(value)
                            }
                        } else {
                            return Result.failure(remainingInput, parser.computeFirstSetSymbols())
                        }
                    } else if parser.computeAcceptsEmpty() {
                        let result = parser.computeParse(remainingInput, followSetSymbols)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, value):
                            remainingInput = remainingInput2
                            results.append(value)
                        }
                    } else {
                        return Result.failureUnavailableInput(remainingInput, parser.computeFirstSetSymbols())
                    }
                }
                return Result.success(remainingInput, results)
            })
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    // swiftlint:disable cyclomatic_complexity function_body_length

    /// Returns a `Parser` which iterates over the array parameter of `Parser`s, transforms the results, and collects
    /// the results in an array.
    ///
    /// - Parameters:
    ///     - parsers: The parsers to invoke in order.
    ///     - func1: The function to transform the result into a new value.
    /// - Returns: A`Parser` which iterates over the array parameter of `Parser`s, transforms the results, and collects
    ///            the results in an array.
    public static func traverse<I, V1, V2>(_ parsers: [Parser<I, V1>], _ func1: @escaping (V1) -> V2)
        -> Parser<I, [V2]> {
        return Parser<I, [V2]>(
            acceptsEmpty: {
                if let firstParser = parsers.first {
                    return firstParser.computeAcceptsEmpty()
                }
                return true
        }(),
            firstSetSymbols: {
                if let firstParser = parsers.first {
                    return firstParser.computeFirstSetSymbols()
                }
                return [Symbol.empty]
        }(),
            parse: { input, followSetSymbols in
                var results: [V2] = []
                var remainingInput = input

                for parser in parsers {
                    if let currentValue = remainingInput.current(), remainingInput.isAvailable {
                        if parser.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                            switch parser.computeParse(remainingInput, followSetSymbols) {
                            case let .success(remainingSuccessInput, value):
                                remainingInput = remainingSuccessInput
                                results.append(func1(value))
                            case let .failure(remainingInput, expectedSymbols):
                                return Result.failure(remainingInput, expectedSymbols)
                            case let .failureUnavailableInput(remainingInput, expectedSymbols):
                                return Result.failureUnavailableInput(remainingInput, expectedSymbols)
                            }
                        } else if parser.computeAcceptsEmpty() {
                            let result = parser.computeParse(remainingInput, followSetSymbols)
                            switch result {
                            case let .failure(remainingInput, symbols):
                                return Result<I, [V2]>.failure(remainingInput, symbols)
                            case let .failureUnavailableInput(remainingInput, symbols):
                                return Result<I, [V2]>.failureUnavailableInput(remainingInput, symbols)
                            case let .success(remainingInput2, value):
                                remainingInput = remainingInput2
                                results.append(func1(value))
                            }
                        } else {
                            return Result.failure(remainingInput, parser.computeFirstSetSymbols())
                        }
                    } else if parser.computeAcceptsEmpty() {
                        let result = parser.computeParse(remainingInput, followSetSymbols)
                        switch result {
                        case let .failure(remainingInput, symbols):
                            return Result<I, [V2]>.failure(remainingInput, symbols)
                        case let .failureUnavailableInput(remainingInput, symbols):
                            return Result<I, [V2]>.failureUnavailableInput(remainingInput, symbols)
                        case let .success(remainingInput2, value):
                            remainingInput = remainingInput2
                            results.append(func1(value))
                        }
                    } else {
                        return Result.failureUnavailableInput(remainingInput, parser.computeFirstSetSymbols())
                    }
                }
                return Result.success(remainingInput, results)
            })
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

}

// swiftlint:enable file_length
