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
    let parse: (A) -> Consumed<Result, B>
}

/// Convenience methods for Parser
public extension Parser {
    /// Convenience method for binding a first parser's return value to a second parser.
    func flatMap<C, Result2>(
        _ func1 : @escaping (Result) -> Parser<B, C, Result2>) -> Parser<A, C, Result2> where B.ConsumeReturn == C {
        return Combinators.bind(self, to: func1)
    }
}

precedencegroup MonodLeftPrecedence {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

infix operator >>-: MonodLeftPrecedence

/// Convenience operator for bind
public func >>-<A, B, Result1, C, Result2>(
    lhs: Parser<A, B, Result1>,
    rhs: @escaping (Result1) -> Parser<B, C, Result2>) -> Parser<A, C, Result2> where B.ConsumeReturn == C {
    return Combinators.bind(lhs, to: rhs)
}

precedencegroup AltPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

infix operator <|>: AltPrecedence

/// Convenience operator for choice
public func <|><A, B, Result1>(
    lhs: Parser<A, B, Result1>,
    rhs: Parser<A, B, Result1>) -> Parser<A, B, Result1> {
    return Combinators.choice(lhs, rhs)
}

precedencegroup AppPrecedence {
    associativity: left
    higherThan: AltPrecedence
    lowerThan: NilCoalescingPrecedence
}

infix operator <*>: AppPrecedence

/// Convenience operator for apply
public func <*><Input1, Input2, Input3, Result1, Result2>(
    lhs: Parser<Input1, Input2, ((Result1) -> Result2)>,
    rhs: Parser<Input2, Input3, Result1>) -> Parser<Input1, Input3, Result2> where Input2.ConsumeReturn == Input3 {
    return Combinators.apply(lhs, rhs)
}

infix operator <^>: AppPrecedence

/// Convenience operator for map
public func <^><Input1, Input2, Result1, Result2>(
    lhs: Parser<Input1, Input2, Result1>,
    rhs: @escaping (Result1) -> Result2) -> Parser<Input1, Input2, Result2> {
    return Combinators.map(lhs, rhs)
}
