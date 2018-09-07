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

/// Combinators create and compose parsers.
public enum Combinators {

    /// Returns a parser which returns the passed in value as a result and does not consume the Input
    public static func returnValue<I, Result1>(_ value: Result1) -> Parser<I, Result1> {
        return Parser { input in
            let messageFunc = {
                ParseError(position: input.position, unexpectedInput: "", expectedProductions: [])
            }
            return Consumed(.empty, .success(value, input, messageFunc))
        }
    }

    /// The parser (in the function parameter)'s parsed result is passed to a function which generates
    /// a second parser, and then the second parser is invoked with the remaining input.
    public static func bind<I, Result1, Result2>(
        _ parser1: Parser<I, Result1>,
        to func1: @escaping (Result1) -> Parser<I, Result2>)
        -> Parser<I, Result2> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.state {
            case .empty:
                switch result1.reply {
                case let .success(value1, remainder1, error1):
                    let result2 = func1(value1).parse(remainder1)
                    switch result2.reply {
                    case let .success(value2, remainder2, error2):
                        return mergeSuccess(element: value2, input: remainder2, error1: error1, error2: error2)
                    case let .error(error2):
                        return mergeError(error1: error1, error2: error2)
                    }
                case let .error(error):
                    return Consumed(.empty, .error(error))
                }
            case .consumed:
                return Consumed(.consumed, {
                    switch result1.reply {
                    case let .success(value1, remainder1, _):
                        return func1(value1).parse(remainder1).reply
                    case let .error(error):
                        return .error(error)
                    }
                })
            }
        }
    }

    /// Returns a Parser for matching a single value
    public static func satisfy<Result1, I>(_ condition: @escaping (Result1) -> Bool)
        -> Parser<I, Result1> where I.Element == Result1 {
        return Parser { input in
            guard let element = input.peek(), !input.isEmpty else {
                let messageFunc = {
                    ParseError(position: input.position, unexpectedInput: "end of input", expectedProductions: [])
                }
                return Consumed(.empty, .error(messageFunc))
            }

            guard condition(element) else {
                let messageFunc = {
                    ParseError(position: input.position, unexpectedInput: "\(element)", expectedProductions: [])
                }
                return Consumed(.empty, .error(messageFunc))
            }

            let messageFunc = {
                ParseError(position: input.position, unexpectedInput: "", expectedProductions: [])
            }
            return Consumed(.consumed, .success(element, input.consume(), messageFunc))
        }
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Returns a Parser for matching a choice between the two parsers
    public static func choice<I, Result1>(
        _ parser1: Parser<I, Result1>,
        _ parser2: Parser<I, Result1>) -> Parser<I, Result1> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.state {
            case .empty:
                switch result1.reply {
                case .error(let error1):
                    let result2 = parser2.parse(input)
                    switch result2.state {
                    case .empty:
                        switch result2.reply {
                        case let .error(error2):
                            return mergeError(error1: error1, error2: error2)
                        case let .success(value2, remainingInput2, error2):
                            return mergeSuccess(
                                element: value2,
                                input: remainingInput2,
                                error1: error1,
                                error2: error2
                            )
                        }
                    case .consumed:
                        return result2
                    }
                case let .success(value1, remainingInput1, error1):
                    let result2 = parser2.parse(input)
                    switch result2.state {
                    case .empty:
                        switch result2.reply {
                        case let .error(error2):
                            return mergeSuccess(
                                element: value1,
                                input: remainingInput1,
                                error1: error1,
                                error2: error2
                            )
                        case let .success(_, _, error2):
                            return mergeSuccess(
                                element: value1,
                                input: remainingInput1,
                                error1: error1,
                                error2: error2
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
    public static func map<I, Result1, Result2>(
        _ parser1: Parser<I, Result1>,
        _ func1: @escaping (Result1) -> Result2) -> Parser<I, Result2> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.reply {
            case let .error(error1):
                switch result1.state {
                case .consumed:
                    return Consumed(.consumed, .error(error1))
                case .empty:
                    return Consumed(.empty, .error(error1))
                }
            case let .success(value1, remainder1, error1):
                return Consumed(result1.state, .success(func1(value1), remainder1, error1))
            }
        }
    }

    /// Sequentially invokes two Parsers while applying the second parser's result into the first parser's function
    public static func apply<I, Result1, Result2>(
        _ parser1: Parser<I, ((Result1) -> Result2)>,
        _ parser2: Parser<I, Result1>) -> Parser<I, Result2> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.reply {
            case let .error(error1):
                return Consumed(result1.state, .error(error1))
            case let .success(value1, remainder1, error1):
                let result2 = Combinators.map(parser2, value1).parse(remainder1)
                switch result1.state {
                case .consumed:
                    return Consumed(.consumed, result2.reply)
                case .empty:
                    switch result2.state {
                    case .empty:
                        switch result2.reply {
                        case let .error(error2):
                            return mergeError(error1: error1, error2: error2)
                        case let .success(value2, remainder2, error2):
                            return mergeSuccess(element: value2, input: remainder2, error1: error1, error2: error2)
                        }
                    case .consumed:
                        return result2
                    }
                }
            }
        }
    }
}
