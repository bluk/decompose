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

    /// The current position in the `Input`. Useful for debugging and error messages.
    var position: Int { get }

    /// Indicates if there are remaining elements available in the view.
    var isAvailable: Bool { get }

    /// Returns the current element.
    ///
    /// - Returns: The current element.
    func current() -> Element?

    /// Returns an `Input` which is offset by 1 element.
    ///
    /// - Returns: The remaining `Input`.
    func advanced() -> Self
}
