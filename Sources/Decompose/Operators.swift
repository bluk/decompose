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

precedencegroup MonodLeftPrecedence {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

infix operator >>-: MonodLeftPrecedence

/// Composes a `Parser` which invokes the `Parser` parameter and uses its returned value to invoke the function
/// parameter, and then invokes the function's returned `Parser`.
///
/// - Parameters:
///     - lhs: The first Parser to invoke the input with.
///     - rhs: A function which will take the `lhs`'s returned value and return another `Parser`, which is
///              then invoked with the remaining input
/// - Returns: A composited `Parser` which binds the parameter `lhs`'s value and passes it to the function
///            `rhs`, which generates a new `Parser` to invoke the remaining input with.
public func >>-<I, V1, V2>(
    lhs: Parser<I, V1>,
    rhs: @escaping (V1) -> Parser<I, V2>) -> Parser<I, V2> {
    return Combinators.bind(lhs, to: rhs)
}

/// Composes a `Parser` which invokes the `Parser` parameter and uses its returned value to invoke the function
/// parameter, and then invokes the function's returned `Parser`.
///
/// - Parameters:
///     - lhs: The first Parser to invoke the input with.
///     - rhs: A function which will take the `lhs`'s returned value and return another `Parser`, which is
///              then invoked with the remaining input
/// - Returns: A composited `Parser` which binds the parameter `lhs`'s value and passes it to the function
///            `rhs`, which generates a new `Parser` to invoke the remaining input with.
public func >><I, V1, V2>(
    lhs: Parser<I, V1>,
    rhs: @escaping () -> Parser<I, V2>) -> Parser<I, V2> {
    return Combinators.then(lhs, to: rhs)
}

precedencegroup AltPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

infix operator <|>: AltPrecedence

/// Convenience operator for choice
public func <|><I, V1>(
    lhs: Parser<I, V1>,
    rhs: Parser<I, V1>) -> Parser<I, V1> {
    return Combinators.choice(lhs, rhs)
}

precedencegroup AppPrecedence {
    associativity: left
    higherThan: AltPrecedence
    lowerThan: NilCoalescingPrecedence
}

infix operator <*>: AppPrecedence

/// Convenience operator for apply
public func <*><I, V1, V2>(
    lhs: Parser<I, ((V1) -> V2)>,
    rhs: Parser<I, V1>) -> Parser<I, V2> {
    return Combinators.apply(lhs, rhs)
}

infix operator <^>: AppPrecedence

/// Convenience operator for map
public func <^><I, V1, V2>(
    lhs: Parser<I, V1>,
    rhs: @escaping (V1) -> V2) -> Parser<I, V2> {
    return Combinators.map(lhs, rhs)
}
