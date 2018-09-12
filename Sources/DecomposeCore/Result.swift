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

/// Represents an empty value.
public enum Empty {
    case empty
}

/// A value type which indicates if the function was successful or not.
public enum Result<I: Input, Value> where I.Element: Comparable, I.Element: Hashable {

    /// The parse was successful with the associated return `Value` and the remaining `Input`.
    case success(I, Value)

    /// The parse failed with the associated return `Value` and possible follow symbols
    case failure(I, Set<Symbol<I.Element>>)

    /// The parse failed due to unavailable input and the associated return `Value` and possible follow symbols
    case failureUnavailableInput(I, Set<Symbol<I.Element>>)

    /// Maps a successful return value with the function parameter.
    ///
    /// - Parameters:
    ///     - func1: The function to map the successful value to a new value.
    /// - Returns: A result that has had its value mapped via the function.
    public func map<MappedValue>(_ func1: (Value) -> MappedValue) -> Result<I, MappedValue> {
        switch self {
        case let .success(remainingInput, value):
            return Result<I, MappedValue>.success(remainingInput, func1(value))
        case let .failure(remainingInput, symbols):
            return Result<I, MappedValue>.failure(remainingInput, symbols)
        case let .failureUnavailableInput(remainingInput, symbols):
            return Result<I, MappedValue>.failureUnavailableInput(remainingInput, symbols)
        }
    }
}
