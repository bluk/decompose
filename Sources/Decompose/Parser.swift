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

/// A parsable function
public struct Parser<A, B, Result> where A: Input, B: Input {
    let parse: (A) -> (Result, B)?
}

/// Convenience methods for Parser
public extension Parser {
    /// Convenience method for binding a first parser's return value to a second parser.
    func flatMap<C, Result2>(_ func1 : @escaping (Result) -> Parser<B, C, Result2>) -> Parser<A, C, Result2> {
        return Combinators.bind(self, to: func1)
    }
}

/// Convenience operator for bind
public func >>=<A, B, Result1, C, Result2>(
    lhs: Parser<A, B, Result1>,
    rhs: @escaping (Result1) -> Parser<B, C, Result2>) -> Parser<A, C, Result2> {
    return Combinators.bind(lhs, to: rhs)
}
