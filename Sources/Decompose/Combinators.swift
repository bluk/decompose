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
        return Parser { input in
            let msgGenerator = {
                ParseMessage(position: input.position, unexpectedInput: "", expectedProductions: [])
            }
            return Consumed(.empty, .success(value, input, msgGenerator))
        }
    }

    /// The parser (in the function parameter)'s parsed result is passed to a function which generates
    /// a second parser, and then the second parser is invoked with the remaining input.
    public static func bind<I, V1, V2>(_ parser1: Parser<I, V1>, to func1: @escaping (V1) -> Parser<I, V2>)
        -> Parser<I, V2> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.state {
            case .empty:
                switch result1.reply {
                case let .success(value1, advancedInput1, msgGenerator1):
                    let parser2 = func1(value1)
                    let result2 = parser2.parse(advancedInput1)
                    switch result2.reply {
                    case let .success(value2, advancedInput2, msgGenerator2):
                        return mergeSuccess(
                            value: value2,
                            input: advancedInput2,
                            msgGenerator1: msgGenerator1,
                            msgGenerator2: msgGenerator2)
                    case let .error(msgGenerator2):
                        return mergeError(msgGenerator1: msgGenerator1, msgGenerator2: msgGenerator2)
                    }
                case let .error(error):
                    return Consumed(.empty, .error(error))
                }
            case .consumed:
                return Consumed(.consumed, {
                    switch result1.reply {
                    case let .success(value1, advancedInput1, _):
                        return func1(value1).parse(advancedInput1).reply
                    case let .error(error):
                        return .error(error)
                    }
                })
            }
        }
    }

    /// Returns a Parser for matching a single value
    public static func satisfy<I, V>(_ condition: @escaping (V) -> Bool) -> Parser<I, V> where I.Element == V {
        return Parser { input in
            guard let element = input.current(), !input.isEmpty else {
                let msgGenerator = {
                    ParseMessage(
                        position: input.position,
                        unexpectedInput: "end of input",
                        expectedProductions: []
                    )
                }
                return Consumed(.empty, .error(msgGenerator))
            }

            guard condition(element) else {
                let msgGenerator = {
                    ParseMessage(position: input.position, unexpectedInput: "\(element)", expectedProductions: [])
                }
                return Consumed(.empty, .error(msgGenerator))
            }

            let msgGenerator = {
                ParseMessage(position: input.position, unexpectedInput: "", expectedProductions: [])
            }
            return Consumed(.consumed, .success(element, input.advanced(), msgGenerator))
        }
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Returns a Parser for matching a choice between the two parsers
    public static func choice<I, V>(
        _ parser1: Parser<I, V>,
        _ parser2: Parser<I, V>) -> Parser<I, V> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.state {
            case .empty:
                switch result1.reply {
                case .error(let msgGenerator1):
                    let result2 = parser2.parse(input)
                    switch result2.state {
                    case .empty:
                        switch result2.reply {
                        case let .error(msgGenerator2):
                            return mergeError(msgGenerator1: msgGenerator1, msgGenerator2: msgGenerator2)
                        case let .success(value2, advancedInput2, msgGenerator2):
                            return mergeSuccess(
                                value: value2,
                                input: advancedInput2,
                                msgGenerator1: msgGenerator1,
                                msgGenerator2: msgGenerator2
                            )
                        }
                    case .consumed:
                        return result2
                    }
                case let .success(value1, advancedInput1, msgGenerator1):
                    let result2 = parser2.parse(input)
                    switch result2.state {
                    case .empty:
                        switch result2.reply {
                        case let .error(msgGenerator2):
                            return mergeSuccess(
                                value: value1,
                                input: advancedInput1,
                                msgGenerator1: msgGenerator1,
                                msgGenerator2: msgGenerator2
                            )
                        case let .success(_, _, msgGenerator2):
                            return mergeSuccess(
                                value: value1,
                                input: advancedInput1,
                                msgGenerator1: msgGenerator1,
                                msgGenerator2: msgGenerator2
                            )
                        }
                    case .consumed:
                        return result2
                    }
                }
            case .consumed:
                return result1
            }
        }
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    /// Maps a Parser's return value over a transforming function
    public static func map<I, V1, V2>(
        _ parser1: Parser<I, V1>,
        _ func1: @escaping (V1) -> V2) -> Parser<I, V2> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.reply {
            case let .error(msgGenerator1):
                switch result1.state {
                case .consumed:
                    return Consumed(.consumed, .error(msgGenerator1))
                case .empty:
                    return Consumed(.empty, .error(msgGenerator1))
                }
            case let .success(value1, advancedInput1, msgGenerator1):
                return Consumed(result1.state, .success(func1(value1), advancedInput1, msgGenerator1))
            }
        }
    }

    /// Sequentially invokes two Parsers while applying the second parser's result into the first parser's function
    public static func apply<I, V1, V2>(
        _ parser1: Parser<I, ((V1) -> V2)>,
        _ parser2: Parser<I, V1>) -> Parser<I, V2> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.reply {
            case let .error(msgGenerator1):
                return Consumed(result1.state, .error(msgGenerator1))
            case let .success(value1, advancedInput1, msgGenerator1):
                let result2 = Combinators.map(parser2, value1).parse(advancedInput1)
                switch result1.state {
                case .consumed:
                    return Consumed(.consumed, result2.reply)
                case .empty:
                    switch result2.state {
                    case .empty:
                        switch result2.reply {
                        case let .error(msgGenerator2):
                            return mergeError(msgGenerator1: msgGenerator1, msgGenerator2: msgGenerator2)
                        case let .success(value2, advancedInput2, msgGenerator2):
                            return mergeSuccess(
                                value: value2,
                                input: advancedInput2,
                                msgGenerator1: msgGenerator1,
                                msgGenerator2: msgGenerator2
                            )
                        }
                    case .consumed:
                        return result2
                    }
                }
            }
        }
    }
}
