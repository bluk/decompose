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
    public static func returnValue<Input1, Result>(_ value: Result) -> Parser<Input1, Input1, Result> {
        return Parser { input in Consumed(.empty, .success(value, input)) }
    }

    /// The parser (in the function parameter)'s parsed result is passed to a function which generates
    /// a second parser, and then the second parser is invoked with the remaining input.
    public static func bind<Input1, Input2, Input3, Result1, Result2>(
        _ parser1: Parser<Input1, Input2, Result1>,
        to func1: @escaping (Result1) -> Parser<Input2, Input3, Result2>)
        -> Parser<Input1, Input3, Result2> where Input2.ConsumeReturn == Input3 {
        return Parser<Input1, Input3, Result2> { input in
            let consumed1 = parser1.parse(input)
            switch consumed1.state {
            case .empty:
                switch consumed1.reply {
                case let .success(result1, remainder2):
                    return func1(result1).parse(remainder2)
                case let .error(error, remainder2):
                    return Consumed(.empty, .error(error, remainder2.consume(count: 0)))
                }
            case .consumed:
                return Consumed(.consumed, {
                    switch consumed1.reply {
                    case let .success(result1, remainder2):
                        return func1(result1).parse(remainder2).reply
                    case let .error(error, remainder2):
                        return .error(error, remainder2.consume(count: 0))
                    }
                })
            }
        }
    }

    /// Returns a Parser for matching a single value
    public static func satisfy<Value, Input1, Input2>(_ condition: @escaping (Value) -> Bool)
        -> Parser<Input1, Input2, Value> where Input1.Value == Value, Input1.ConsumeReturn == Input2 {
        return Parser { input in
            guard let value = input.peek(), condition(value) else {
                return Consumed(.empty, .error(nil, input.consume(count: 0)))
            }
            return Consumed(.consumed, .success(value, input.consume()))
        }
    }

    /// Returns a Parser for matching a choice between the two parsers
    public static func choice<Input1, Input2, Result1>(
        _ parser1: Parser<Input1, Input2, Result1>,
        _ parser2: Parser<Input1, Input2, Result1>)
        -> Parser<Input1, Input2, Result1> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.state {
            case .consumed:
                return result1
            case .empty:
                switch result1.reply {
                case .success:
                    let result2 = parser2.parse(input)
                    switch result2.state {
                    case .consumed:
                        return result2
                    case .empty:
                        switch result2.reply {
                        case .error:
                            return Consumed<Result1, Input2>(.empty, result1.reply)
                        case .success:
                            return result2
                        }
                    }
                case .error:
                    return parser2.parse(input)
                }
            }
        }
    }

    /// Maps a Parser's return value over a transforming function
    public static func map<Input1, Input2, Result1, Result2>(
        _ parser1: Parser<Input1, Input2, Result1>,
        _ func1: @escaping (Result1) -> Result2) -> Parser<Input1, Input2, Result2> {
        return Parser { input in
            let result1 = parser1.parse(input)
            switch result1.reply {
            case let .error(error, remainder2):
                switch result1.state {
                case .consumed:
                    return Consumed(.consumed, .error(error, remainder2))
                case .empty:
                    return Consumed(.empty, .error(error, remainder2))
                }
            case let .success(value1, remainder2):
                return Consumed(result1.state, .success(func1(value1), remainder2))
            }
        }
    }

    /// Sequentially invokes two Parsers while applying the second parser's result into the first parser's function
    public static func apply<Input1, Input2, Input3, Result1, Result2>(
        _ parser1: Parser<Input1, Input2, ((Result1) -> Result2)>,
        _ parser2: Parser<Input2, Input3, Result1>) -> Parser<Input1, Input3, Result2>
        where Input2.ConsumeReturn == Input3 {
        return Parser { input in
            let output1 = parser1.parse(input)
            switch output1.reply {
            case let .error(error, remainder2):
                return Consumed(output1.state, .error(error, remainder2.consume(count: 0)))
            case let .success(value1, remainder2):
                let output2 = Combinators.map(parser2, value1).parse(remainder2)
                switch output1.state {
                case .consumed:
                    return Consumed(.consumed, output2.reply)
                case .empty:
                    return output2
                }
            }
        }
    }
}
