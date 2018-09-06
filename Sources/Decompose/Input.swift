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

/// A view for a collection of values.
public protocol Input {

    /// The individual element type.
    associatedtype Element

    /// After data is consumed, the remaining unconsumed elements is returned via an `Input`
    associatedtype RemainingInput where RemainingInput: Input

    /// The current position in the `Input`. Useful for debugging and error messages.
    var position: Int { get }

    /// If there are no more elements available in the view.
    var isEmpty: Bool { get }

    /// Returns the current element.
    ///
    /// - Returns: The current element.
    func peek() -> Element?

    /// Returns the current and next `count - 1` number of elements.
    ///
    /// - Parameters:
    ///     - count: The number of elements to peek.
    /// - Returns: The current and next `count - 1` number of elements.
    /// - Precondition: `count` must be >= 0.
    func peek(count: Int) -> [Element]

    /// Consumes the current element and return an `Input` representing the remaining data.
    ///
    /// - Returns: The remaining `Input`.
    func consume() -> RemainingInput

    /// Consumes the current and next `count - 1` number of elements and return an `Input`
    /// representing the remaining data.
    ///
    /// - Parameters:
    ///     - count: Up to the number of elements to consume. `0` is a valid value.
    /// - Returns: The remaining `Input`.
    /// - Precondition: `count` must be >= 0.
    func consume(count: Int) -> RemainingInput
}

/// Default implementation of methods for Input.
public extension Input {

    /// Consumes the current element and return an `Input` representing the remaining data.
    ///
    /// - Returns: The remaining `Input`.
    func consume() -> RemainingInput {
        return consume(count: 1)
    }
}
