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

/// An error type for ParseErrors
public struct ParseError: Error {
    let position: Int
    let unexpectedInput: String
    let expectedProductions: [String]
}

internal func mergeSuccess<I: Input, V>(
    value: V,
    input: I,
    error1: @escaping () -> (ParseError),
    error2: @escaping () -> (ParseError)
    ) -> Consumed<I, V> {
    return Consumed(.empty, Reply.success(value, input, merge(error1, error2)))
}

internal func mergeError<I: Input, V>(
    error1:  @escaping () -> (ParseError),
    error2: @escaping () -> (ParseError)
    ) -> Consumed<I, V> {
    return Consumed(.empty, Reply.error(merge(error1, error2)))
}

internal func merge(
    _ error1: @escaping () -> (ParseError),
    _ error2:  @escaping  () -> (ParseError)
    ) -> (() -> (ParseError)) {
    return {
        let err1 = error1()
        let err2 = error2()

        return ParseError(
            position: err1.position,
            unexpectedInput: err1.unexpectedInput,
            expectedProductions: err1.expectedProductions + err2.expectedProductions
        )
    }
}

/// Determines if the parse operation was a success
public enum Reply<I: Input, Value> {
    case success(Value, I, () -> ParseError)
    case error(() -> ParseError)

    /// The message to use when a parsing error occurs. For success messages, it can be used as a possibility.
    public var message: ParseError {
        switch self {
        case .success(_, _, let messageFunc):
            return messageFunc()
        case let .error(messageFunc):
            return messageFunc()
        }
    }
}

/// Whether any of the Input was consumed
public enum ConsumedState {
    case consumed
    case empty
}

/// Consumed is a wrapper type to allow lazy computation of the actual state.
///
/// Access the `value` property to get the real value.
public class Consumed<I: Input, V> {

    var state: ConsumedState

    lazy var reply: Reply<I, V> = {
        self.compute()
    }()

    let compute: () -> Reply<I, V>

    init(_ state: ConsumedState, _ value: Reply<I, V>) {
        self.state = state
        compute = { value }
    }

    init(_ state: ConsumedState, _ compute: @escaping () -> Reply<I, V>) {
        self.state = state
        self.compute = compute
    }
}
