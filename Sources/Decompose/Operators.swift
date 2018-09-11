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

precedencegroup MonadLeftPrecedence {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

precedencegroup ChoiceLeftPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

infix operator <|>: ChoiceLeftPrecedence

/// Returns a `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
///
/// - Parameters:
///     - lhs: The first `Parser` to invoke the input with.
///     - rhs: The second `Parser` to invoke the input with if the first `Parser` fails.
/// - Returns: A `Parser` which invokes the first `Parser`, and if it fails, invokes the second `Parser`.
public func <|><I, V1>(
    lhs: Parser<I, V1>,
    rhs: Parser<I, V1>) -> Parser<I, V1> {
    return Combinators.or(lhs, rhs)
}

precedencegroup ApplicativeFunctorLeftPrecedence {
    associativity: left
    higherThan: ChoiceLeftPrecedence
    lowerThan: NilCoalescingPrecedence
}

infix operator <*>: ApplicativeFunctorLeftPrecedence

/// Sequentially invokes two Parsers while applying the second parser's result into the first parser's function
/// with the label parameter.
///
/// - Parameters:
///     - lhs: The first `Parser` to invoke
///     - rhs: The second `Parser` to invoke
/// - Returns: A `Parser` which invokes the first `Parser` parameter, then the second `Parser` parameter and then
///           invokes the first `Parser`'s returned function value with the second `Parser`'s returned value.
public func <*><I, V1, V2>(
    lhs: Parser<I, ((V1) -> V2)>,
    rhs: Parser<I, V1>) -> Parser<I, V2> {
    return Combinators.apply(lhs, rhs)
}

infix operator <^>: ApplicativeFunctorLeftPrecedence

/// Maps a `Parser`'s value using the function parameter.
///
/// - Parameters:
///     - lhs: The `Parser` to invoke the input with.
///     - rhs: A function which will transform the `parser`'s return value into a new value.
/// - Returns: A Parser which transforms the original value to a value using the function.
public func <^><I, V1, V2>(
    lhs: @escaping (V1) -> V2,
    rhs: Parser<I, V1>) -> Parser<I, V2> {
    return Combinators.map(rhs, lhs)
}

precedencegroup ApplicativeFunctorSequenceLeftPrecedence {
    associativity: left
    higherThan: ApplicativeFunctorLeftPrecedence
    lowerThan: NilCoalescingPrecedence
}

infix operator *>: ApplicativeFunctorSequenceLeftPrecedence

/// Sequentially invokes two Parsers while ignoring the first value.
///
/// - Parameters:
///     - lhs: The first `Parser` to invoke
///     - rhs: The second `Parser` to invoke
/// - Returns: A `Parser` which invokes the first `Parser` parameter, then the second `Parser` parameter and then
///            returns the second `Parser`'s returned value.
public func *><I, V1, V2>(
    lhs: Parser<I, V1>,
    rhs: Parser<I, V2>) -> Parser<I, V2> {
    return lhs.andR(rhs)
}

infix operator <*: ApplicativeFunctorSequenceLeftPrecedence

/// Sequentially invokes two Parsers while ignoring the second value.
///
/// - Parameters:
///     - lhs: The first `Parser` to invoke
///     - rhs: The second `Parser` to invoke
/// - Returns: A `Parser` which invokes the first `Parser` parameter, then the first `Parser` parameter and then
///            returns the first `Parser`'s returned value.
public func <*<I, V1, V2>(
    lhs: Parser<I, V1>,
    rhs: Parser<I, V2>) -> Parser<I, V1> {
    return lhs.andL(rhs)
}

infix operator <??>: MonadLeftPrecedence

/// Returns a `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
/// use the value parameter.
///
/// - Parameters:
///     - lhs: The Parser to attempt
///     - rhs: The value to return if the `lhs` parameter is not successful
/// - Returns: A `Parser` which attempts the parser parameter and if it succeeds, return the value, but if it fails,
///            use the value parameter.
public func <??><I, V1>(
    lhs: Parser<I, V1>,
    rhs: V1) -> Parser<I, V1> {
    return Combinators.option(lhs, rhs)
}
