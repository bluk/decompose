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

/// A consumable input value.
public protocol Input {

    /// The individual type that will be evaluated
    associatedtype Value

    /// The Input value to return
    associatedtype ConsumeReturn where ConsumeReturn: Input

    /// The current position of the Input
    var position: Int { get }

    /// If there is no more input
    var isEmpty: Bool { get }

    /// Returns the current value
    func peek() -> Value?

    /// Returns up to `count` number of values
    func peek(count: Int) -> [Value]

    /// Consumes the current value
    func consume() -> ConsumeReturn

    /// Consumes up to the current `count` number of values
    func consume(count: Int) -> ConsumeReturn
}

/// Default implementation of Input
public extension Input {

    /// Consumes the current value
    func consume() -> ConsumeReturn {
        return consume(count: 1)
    }
}

open class StringInput: Input {

    public init(input: String, position: Int = 0) {
        self.value = input
        self.position = position
    }

    let value: String

    public var position: Int

    public var isEmpty: Bool {
        return self.position >= self.value.count
    }

    public func peek() -> Character? {
        guard position < value.count else {
            return nil
        }
        let index = value.index(value.startIndex, offsetBy: position)
        return value[index]
    }

    public func peek(count: Int) -> [Character] {
        guard position < value.count else {
            return []
        }
        let startIndex = value.index(value.startIndex, offsetBy: position)
        let endIndex = value.index(value.startIndex, offsetBy: position + count)
        return [Character](value[startIndex..<endIndex])
    }

    public func consume(count: Int) -> StringInput {
        return StringInput(input: value, position: position + count)
    }
}
