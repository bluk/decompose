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
public struct Parser<I, V> where I: Input {
    let parse: (I) -> Consumed<I, V>
}

/// Convenience methods for Parser
public extension Parser {
    /// Convenience method for binding a first parser's return value to a second parser.
    func flatMap<V2>(
        _ func1 : @escaping (V) -> Parser<I, V2>) -> Parser<I, V2> {
        return Combinators.bind(self, to: func1)
    }
}
