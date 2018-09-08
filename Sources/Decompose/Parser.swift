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

/// A value type for the `parse` function.
public struct Parser<I, V> where I: Input {

    /// A function which takes an `Input` and returns a type which indicates if the `Input` is consumed when parsing
    /// the result and either a parsed value or an error message.
    public let parse: (I) -> Consumed<I, V>
}

/// Convenience methods for `Parser`.
public extension Parser {

    /// Binds this `Parser`'s return value to a function which generates another `Parser`.
    ///
    /// - Parameters:
    ///     - func1: The function to bind the value of this parser to.
    /// - Returns: A bound `Parser`.
    func flatMap<V2>(_ func1 : @escaping (V) -> Parser<I, V2>) -> Parser<I, V2> {
        return Combinators.bind(self, to: func1)
    }

    /// Maps this `Parser`'s value using the function parameter.
    ///
    /// - Parameters:
    ///     - func1: A function which will transform the `parser`'s return value into a new value.
    /// - Returns: A Parser which transforms the original value to a value using the function.
    func map<V2>(_ func1: @escaping (V) -> V2) -> Parser<I, V2> {
        return Combinators.map(self, func1)
    }
}
