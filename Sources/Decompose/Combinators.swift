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
            Consumed(.empty, .success(value, input, { ParseMessage(position: input.position) }))
        }
    }

    /// Composes a `Parser` which invokes the `Parser` parameter and uses its returned value to invoke the function
    /// parameter, and then invokes the function's returned `Parser`.
    ///
    /// - Parameters:
    ///     - parser1: The first Parser to invoke the input with.
    ///     - func1: A function which will take the `parser1`'s returned value and return another `Parser`, which is
    ///              then invoked with the remaining input
    /// - Returns: A composited `Parser` which binds the parameter `parser1`'s value and passes it to the function
    ///            `func1`, which generates a new `Parser` to invoke the remaining input with.
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
                    switch result2.state {
                    case .consumed:
                        return result2
                    case .empty:
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

    /// Composes a `Parser` which invokes the `Parser` parameter and then invokes the function's returned `Parser`.
    ///
    /// - Parameters:
    ///     - parser1: The first `Parser` to invoke the input with.
    ///     - func1: A function which will return a `Parser`, which is then invoked with the remaining input
    /// - Returns: A composited `Parser` which invoke's the first parser and then uses the function to return a
    ///            `Parser` to invoke with the remaining `Input`.
    public static func then<I, V1, V2>(_ parser1: Parser<I, V1>, to func1: @escaping () -> Parser<I, V2>)
        -> Parser<I, V2> {
            return Parser { input in
                let result1 = parser1.parse(input)
                switch result1.state {
                case .empty:
                    switch result1.reply {
                    case let .success(_, advancedInput1, msgGenerator1):
                        let parser2 = func1()
                        let result2 = parser2.parse(advancedInput1)
                        switch result2.state {
                        case .consumed:
                            return result2
                        case .empty:
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
                        }
                    case let .error(error):
                        return Consumed(.empty, .error(error))
                    }
                case .consumed:
                    return Consumed(.consumed, {
                        switch result1.reply {
                        case let .success(_, advancedInput1, _):
                            return func1().parse(advancedInput1).reply
                        case let .error(error):
                            return .error(error)
                        }
                    })
                }
            }
    }

    /// Returns a `Parser` which passes an element to the `condition` function and succeeds if the `condition` returns
    /// true or fails if `condition` returns false.
    ///
    /// - Parameters:
    ///     - condition: A function which is passed in an element, and determines if the element meets some criteria.
    /// - Returns: A `Parser` which returns an element if it succeeds the condition.
    public static func satisfy<I, V>(_ condition: @escaping (V) -> Bool) -> Parser<I, V> where I.Element == V {
        return Parser { input in
            guard let element = input.current(), !input.isEmpty else {
                let msgGenerator = {
                    ParseMessage(position: input.position, unexpectedInput: "end of input")
                }
                return Consumed(.empty, .error(msgGenerator))
            }

            guard condition(element) else {
                let msgGenerator = {
                    ParseMessage(position: input.position, unexpectedInput: "\(element)")
                }
                return Consumed(.empty, .error(msgGenerator))
            }

            let msgGenerator = {
                ParseMessage(position: input.position)
            }
            return Consumed(.consumed, .success(element, input.advanced(), msgGenerator))
        }
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    /// Returns a `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
    ///
    /// - Parameters:
    ///     - parser1: The first `Parser` to invoke the input with.
    ///     - parser2: The second `Parser` to invoke the input with if the first `Parser` fails.
    /// - Returns: A `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
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

    /// Maps a `Parser`'s value using the function parameter.
    ///
    /// - Parameters:
    ///     - parser: The `Parser` to invoke the input with.
    ///     - func1: A function which will transform the `parser`'s return value into a new value.
    /// - Returns: A Parser which transforms the original value to a value using the function.
    public static func map<I, V1, V2>(
        _ parser: Parser<I, V1>,
        _ func1: @escaping (V1) -> V2) -> Parser<I, V2> {
        return Combinators.bind(parser, to: { Combinators.pure(func1($0)) })
    }

    /// Sequentially invokes two Parsers while applying the second parser's result into the first parser's function
    /// with the label parameter.
    ///
    /// - Parameters:
    ///     - parser1: The first `Parser` to invoke
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes the first `Parser` parameter, then the second `Parser` parameter and then
    ///           invokes the first `Parser`'s returned function value with the second `Parser`'s returned value.
    public static func apply<I, V1, V2>(
        _ parser1: Parser<I, ((V1) -> V2)>,
        _ parser2: Parser<I, V1>) -> Parser<I, V2> {
        return Combinators.bind(parser1, to: { func1 in
            Combinators.map(Combinators.bind(parser2, to: { value2 in
                Combinators.pure(value2)
            }), { value2 in
                func1(value2)
            })
        })
    }

    /// Instantiates a new `Parser` which will overwrite the parameter `Parser`'s `ParseMessage`'s `expectedProductions`
    /// with the label parameter.
    ///
    /// - Parameters:
    ///     - parser: The `Parser` to override `ParseMessage`'s `expectedProductions` with.
    ///     - label: The value of any produced `ParseMessage`'s `expectedProductions`.
    /// - Returns: A `Parser` which has a label attached for any produced `ParseMessage`s.
    public static func label<I, V>(_ parser: Parser<I, V>, with label: String) -> Parser<I, V> {
        return Parser { input in
            let result = parser.parse(input)
            switch result.state {
            case .empty:
                switch result.reply {
                case let .error(msgGenerator):
                    let labelMsgGenerator: () -> ParseMessage = {
                        let originalMsg = msgGenerator()
                        return ParseMessage(
                            position: originalMsg.position,
                            unexpectedInput: originalMsg.unexpectedInput,
                            expectedProductions: [label]
                        )
                    }
                    return Consumed(.empty, .error(labelMsgGenerator))
                case let .success(value, advancedInput, msgGenerator):
                    let labelMsgGenerator: () -> ParseMessage = {
                        let originalMsg = msgGenerator()
                        return ParseMessage(
                            position: originalMsg.position,
                            unexpectedInput: originalMsg.unexpectedInput,
                            expectedProductions: [label]
                        )
                    }
                    return Consumed(.empty, .success(value, advancedInput, labelMsgGenerator))
                }
            case .consumed:
                return result
            }
        }
    }

    /// Instantiates a `Parser` which only fails.
    ///
    /// - Returns: A `Parser` which only fails.
    public static func fail<I, V>() -> Parser<I, V> {
        return Parser { input in
            Consumed(.empty, .error({ ParseMessage(position: input.position) }))
        }
    }

    /// Instantiates a `Parser` which succeeds if the end of the input is reached.
    ///
    /// - Returns: A `Parser` which succeeds if the end of the input is reached.
    public static func endOfInput<I>() -> Parser<I, Bool> {
        return Parser { input in
            if input.isEmpty {
                return Consumed(
                    .empty,
                    .success(true, input, {
                        ParseMessage(
                            position: input.position,
                            unexpectedInput: "",
                            expectedProductions: ["end of input"]
                        )
                    }))
            }
            var unexpectedInput = "not end of input"
            if let element = input.current() {
                unexpectedInput = "\(element)"
            }
            return Consumed(
                .empty,
                .error({
                    ParseMessage(
                        position: input.position,
                        unexpectedInput: "\(unexpectedInput)",
                        expectedProductions: ["end of input"])
                }))
        }
    }
}
