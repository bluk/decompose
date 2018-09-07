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

/// Messages which can be used if the parse function is unsuccessful.
public struct ParseMessage {

    /// The position in the `Input` for this message.
    public let position: Int

    /// The unexpected `Input` element as a `String`.
    public let unexpectedInput: String

    /// A set of expected productions
    public let expectedProductions: [String]
}

/// A function to generate an error message.
public typealias ParseMessageGenerator = () -> ParseMessage

/// A value type which indicates if the function was successful or not.
public enum Reply<I: Input, Value> {

    /// The parse was successful with the associated return `Value`, the advanced `Input`, and a
    /// `ParseMessageGenerator`.
    case success(Value, I, ParseMessageGenerator)

    /// The parse failed with an associated `ParseMessageGenerator`.
    case error(ParseMessageGenerator)

    /// The message to use when a parsing error occurs. For success messages, it can be used as a possibility.
    public var message: ParseMessage {
        switch self {
        case .success(_, _, let messageGenerator):
            return messageGenerator()
        case let .error(messageGenerator):
            return messageGenerator()
        }
    }
}

/// Indicates whether the `Input` was advanced or not.
public enum ConsumedState {

    /// The `Input` was advanced.
    case consumed

    /// The `Input` was not advanced.
    case empty
}

/// A wrapper result type.
public final class Consumed<I: Input, V> {

    /// Indicates whether the `Input` was advanced or not when producing this result.
    public let state: ConsumedState

    /// Contains the return state of the function execution.
    public lazy var reply: Reply<I, V> = {
        self.computeReply()
    }()

    /// A function which will generate the `Reply` value.
    private let computeReply: () -> Reply<I, V>

    /// Initializes with the state and an existing `Reply` value.
    ///
    /// - Parameters:
    ///     - state: Indicates whether the `Input` was advanced or not when producing this result.
    ///     - reply: The return state of the function execution.
    public init(_ state: ConsumedState, _ reply: Reply<I, V>) {
        self.state = state
        self.computeReply = { reply }
    }

    /// Initializes with the state and a function which will generate the `Reply` value.
    ///
    /// Useful for when the Reply value should not be created yet but the consumption state is already known.
    ///
    /// - Parameters:
    ///     - state: Indicates whether the `Input` was advanced or not when producing this result.
    ///     - computeReply: A function to generate the return state of the function execution.
    public init(_ state: ConsumedState, _ computeReply: @escaping () -> Reply<I, V>) {
        self.state = state
        self.computeReply = computeReply
    }
}

internal func mergeSuccess<I: Input, V>(
    value: V,
    input: I,
    msgGenerator1: @escaping () -> (ParseMessage),
    msgGenerator2: @escaping () -> (ParseMessage)
    ) -> Consumed<I, V> {
    return Consumed(.empty, Reply.success(value, input, merge(msgGenerator1, msgGenerator2)))
}

internal func mergeError<I: Input, V>(
    msgGenerator1:  @escaping () -> (ParseMessage),
    msgGenerator2: @escaping () -> (ParseMessage)
    ) -> Consumed<I, V> {
    return Consumed(.empty, Reply.error(merge(msgGenerator1, msgGenerator2)))
}

internal func merge(
    _ msgGenerator1: @escaping () -> (ParseMessage),
    _ msgGenerator2:  @escaping  () -> (ParseMessage)
    ) -> (() -> (ParseMessage)) {
    return {
        let err1 = msgGenerator1()
        let err2 = msgGenerator2()

        return ParseMessage(
            position: err1.position,
            unexpectedInput: err1.unexpectedInput,
            expectedProductions: err1.expectedProductions + err2.expectedProductions
        )
    }
}
