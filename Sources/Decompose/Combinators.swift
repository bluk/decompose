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

/// Combinators create parsers.
public enum Combinators {

    /// Returns a parser which returns the passed in value as a result and does not consume the Input
    public static func returnValue<Input1, Result>(_ value: Result) -> Parser<Input1, Input1, Result> {
        return Parser { (value, $0) }
    }

    /// The parser (in the function parameter)'s parsed result is passed to a function which generates
    /// a second parser, and then the second parser is invoked with the remaining input.
    public static func bind<Input1, Input2, Input3, Result1, Result2>(
        _ parser1: Parser<Input1, Input2, Result1>,
        to func1: @escaping (Result1) -> Parser<Input2, Input3, Result2>)
        -> Parser<Input1, Input3, Result2> {
            return Parser<Input1, Input3, Result2> { input in
                guard let (result1, remainder1) = parser1.parse(input) else {
                    return nil
                }
                let parser2 = func1(result1)
                return parser2.parse(remainder1)
            }
    }

    /// Returns a Parser for matching a single value
    public static func satisfy<Value, Input1, Input2>(_ condition: @escaping (Value) -> Bool)
        -> Parser<Input1, Input2, Value> where Input1.Value == Value, Input1.ConsumeReturn == Input2 {
        return Parser { input in
            guard let value = input.peek(), condition(value) else {
                return nil
            }
            return (value, input.consume())
        }
    }

    /// Returns a Parser for matching a choice between the two parsers
    public static func choice<Input1, Input2, Result1>(
        _ parser1: Parser<Input1, Input2, Result1>,
        _ parser2: Parser<Input1, Input2, Result1>)
        -> Parser<Input1, Input2, Result1> {
        return Parser { input in
            if let (result1, remainder1) = parser1.parse(input) {
                return (result1, remainder1)
            }

            return parser2.parse(input)
        }
    }
}
