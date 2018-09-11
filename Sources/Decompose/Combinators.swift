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
        return Parser(
            acceptsEmpty: true,
            firstSetSymbols: [Symbol.empty]
        ) { input, _ in
            Result.success(input, value)
        }
    }

    /// Instantiates a `Parser` which accepts the symbol parameter and advances the `Input`.
    ///
    /// - Parameters:
    ///     - symbol: The value to expect.
    /// - Returns: A `Parser` which accepts the symbol parameter and and advances the `Input`.
    public static func symbol<I, S>(_ symbol: S) -> Parser<I, S> where S == I.Element {
        return Parser(acceptsEmpty: false, firstSetSymbols: [Symbol.value(symbol)]) { input, _ in
            Result.success(input.advanced(), symbol)
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
        return Parser(
            acceptsEmpty: false,
            firstSetSymbols: [Symbol.predicate(name: conditionName, condition)]
        ) { input, _ in
            Result.success(input.advanced(), input.current()!)
        }
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
        return Parser(
            acceptsEmpty: parser1.computeAcceptsEmpty() || parser2.computeAcceptsEmpty(),
            firstSetSymbols: parser1.computeFirstSetSymbols().union(parser2.computeFirstSetSymbols())
        ) { input, followSetSymbols in
            if input.isAvailable {
                let currentValue = input.current()!
                if parser1.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                    return parser1.apply(input, followSetSymbols)
                }

                if parser2.computeFirstSetSymbols().contains(where: { $0.matches(currentValue) }) {
                    return parser2.apply(input, followSetSymbols)
                }

                if followSetSymbols.contains(where: { $0.matches(currentValue) }) {
                    if parser1.computeAcceptsEmpty() {
                        return parser1.apply(input, followSetSymbols)
                    }

                    if parser2.computeAcceptsEmpty() {
                        return parser2.apply(input, followSetSymbols)
                    }
                }

                return Result.failure(input, parser1.computeFirstSetSymbols())
            } else {
                if parser1.computeAcceptsEmpty() {
                    return parser1.apply(input, followSetSymbols)
                } else if parser2.computeAcceptsEmpty() {
                    return parser2.apply(input, followSetSymbols)
                } else {
                    return Result.failureUnavailableInput(input, parser1.computeFirstSetSymbols())
                }
            }
        }
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
        return Parser(
            acceptsEmpty: parser.computeAcceptsEmpty(),
            firstSetSymbols: parser.computeFirstSetSymbols(),
            parse: { input, followSetSymbols in
                parser.apply(input, followSetSymbols).map(func1)
            }
        )
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
        return Parser(
            acceptsEmpty: parser1.computeAcceptsEmpty() && parser2.computeAcceptsEmpty(),
            firstSetSymbols: {
                let symbols = parser1.computeFirstSetSymbols()
                if parser1.computeAcceptsEmpty() {
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

                let functionReply = parser1.apply(input, followSetSymbolsForFunction)
                switch functionReply {
                case let .failure(remainingInput, symbols):
                    return Result<I, V2>.failure(remainingInput, symbols)
                case let .failureUnavailableInput(remainingInput, symbols):
                    return Result<I, V2>.failureUnavailableInput(remainingInput, symbols)
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
                    return parser2.apply(remainingInput, followSetSymbols).map(value)
                }
            })
    }

    /// Instantiates a `Parser` which only fails.
    ///
    /// - Returns: A `Parser` which only fails.
    public static func fail<I, V>() -> Parser<I, V> {
        return Parser(
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
        return Parser(acceptsEmpty: true, firstSetSymbols: [Symbol.empty]) { input, _ in
            if !input.isAvailable {
                return Result.success(input, Empty.empty)
            }
            return Result.failure(input, [Symbol.empty])
        }
    }

    /// Instantiates a `Parser` which constructs its real parser via a function.
    ///
    /// Useful in instances of recursion where the recursive call can be wrapped in a closure.
    ///
    /// - Parameters:
    ///     - func1: A function which returns a parser.
    /// - Returns: A `Parser` which calls the returned parser from `func1`.
    public static func wrap<I, V>(_ func1: @escaping () -> Parser<I, V>) -> Parser<I, V> {
        return Parser(
            acceptsEmpty: func1().computeAcceptsEmpty(),
            firstSetSymbols: func1().computeFirstSetSymbols()
        ) {
            func1().apply($0, $1)
        }
    }
}
