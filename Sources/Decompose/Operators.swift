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

/// Convenience operator for bind
public func >>-<A, Result1, Result2>(
    lhs: Parser<A, Result1>,
    rhs: @escaping (Result1) -> Parser<A, Result2>) -> Parser<A, Result2> {
    return Combinators.bind(lhs, to: rhs)
}

precedencegroup AltPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

infix operator <|>: AltPrecedence

/// Convenience operator for choice
public func <|><A, Result1>(
    lhs: Parser<A, Result1>,
    rhs: Parser<A, Result1>) -> Parser<A, Result1> {
    return Combinators.choice(lhs, rhs)
}

precedencegroup AppPrecedence {
    associativity: left
    higherThan: AltPrecedence
    lowerThan: NilCoalescingPrecedence
}

infix operator <*>: AppPrecedence

/// Convenience operator for apply
public func <*><Input1, Result1, Result2>(
    lhs: Parser<Input1, ((Result1) -> Result2)>,
    rhs: Parser<Input1, Result1>) -> Parser<Input1, Result2> {
    return Combinators.apply(lhs, rhs)
}

infix operator <^>: AppPrecedence

/// Convenience operator for map
public func <^><Input1, Result1, Result2>(
    lhs: Parser<Input1, Result1>,
    rhs: @escaping (Result1) -> Result2) -> Parser<Input1, Result2> {
    return Combinators.map(lhs, rhs)
}
