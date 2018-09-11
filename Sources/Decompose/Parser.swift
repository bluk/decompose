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
        self.apply = parse
    }

    /// Returns true if this `Parser` accepts an empty input.
    public let computeAcceptsEmpty: () -> Bool

    /// Returns the first set of symbols which can be accepted as input.
    public let computeFirstSetSymbols: () -> Set<Symbol<I.Element>>

    /// A function which takes an `Input` and a set of follow symbols and returns a type which either a parsed value
    /// or an error message.
    public let apply: (I, Set<Symbol<I.Element>>) -> Result<I, V>

    /// A method to run the parser with an `Input`.
    public func parse(_ input: I) -> Result<I, V> {
        let parserAndEndOfInput = self <* Combinators.endOfInput()
        if computeAcceptsEmpty() {
            return parserAndEndOfInput.apply(input, [Symbol.empty])
        } else if !input.isAvailable {
            return Result.failureUnavailableInput(input, computeFirstSetSymbols())
        } else if let current = input.current(), computeFirstSetSymbols().contains(where: { $0.matches(current) }) {
            return parserAndEndOfInput.apply(input, [Symbol.empty])
        } else {
            return Result.failure(input, computeFirstSetSymbols())
        }
    }
}

/// Convenience methods for `Parser`.
public extension Parser {

    /// Maps this `Parser`'s value using the function parameter.
    ///
    /// - Parameters:
    ///     - func1: A function which will transform the `parser`'s return value into a new value.
    /// - Returns: A Parser which transforms the original value to a value using the function.
    func map<V2>(_ func1: @escaping (V) -> V2) -> Parser<I, V2> {
        return Combinators.map(self, func1)
    }

    /// Sequentially invokes this `Parser`, then the parameter argument, and finally invokes the second parser's result
    /// into this parser's function.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes this `Parser`, then the parameter argument, and finally invokes the second
    ///            parser's result into this parser's function.
    func apply<V2, V3>(_ parser2: Parser<I, V2>) -> Parser<I, V3> where V == (V2) -> V3 {
        return Combinators.apply(self, parser2)
    }

    /// Returns a `Parser` which invokes this `Parser`, and if it fails, invokes the second `Parser`.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke the input with if this `Parser` fails.
    /// - Returns: A `Parser` which invokes this `Parser`, and if it fails, invokes the second `Parser`.
    func or(_ parser2: Parser<I, V>) -> Parser<I, V> {
        return Combinators.or(self, parser2)
    }

    /// Sequentially invokes this `Parser` and then the `Parser` argument while ignoring the second value.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes this `Parser`, then the second `Parser` parameter and then
    ///            returns this `Parser`'s returned value.
    func andL<V2>(_ parser2: Parser<I, V2>) -> Parser<I, V> {
        return Combinators.apply(map({ first in { _ in first } }), parser2)
    }

    /// Sequentially invokes this `Parser` and then the `Parser` argument while ignoring the first value.
    ///
    /// - Parameters:
    ///     - parser2: The second `Parser` to invoke
    /// - Returns: A `Parser` which invokes this `Parser`, then the second `Parser` parameter and then
    ///            returns the second `Parser`'s returned value.
    func andR<V2>(_ parser2: Parser<I, V2>) -> Parser<I, V2> {
        return Combinators.apply(map({ _ in { second in second } }), parser2)
    }

    /// Returns a `Parser` which invokes this `Parser` zero or more times.
    ///
    /// - Returns: A `Parser` which invokes this `Parser` zero or more times.
    func many() -> Parser<I, [V]> {
        return Combinators.many(self)
    }

    /// Returns a `Parser` which invokes this `Parser` one or more times.
    ///
    /// - Returns: A `Parser` which invokes this `Parser` one or more times.
    func many1() -> Parser<I, [V]> {
        return Combinators.many1(self)
    }

    /// Returns a `Parser` which discards the return value of this `parser` zero or more times.
    ///
    /// - Returns: A `Parser` which discards the return value of this `parser` zero or more times.
    func skipMany() -> Parser<I, Empty> {
        return Combinators.skipMany(self)
    }

    /// Returns a `Parser` which discards the return value of this `parser` one or more times.
    ///
    /// - Returns: A `Parser` which discards the return value of this `parser` oneor more times.
    func skipMany1() -> Parser<I, Empty> {
        return Combinators.skipMany1(self)
    }
}
