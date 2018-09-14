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

/// Use a `String` as an `Input` type.
public struct StringInput: Input, Equatable, Hashable {

    public init(_ value: String, position: Int = 0) {
        self.value = value
        self.position = position
    }

    let value: String

    public let position: Int

    public var isAvailable: Bool {
        return self.position < self.value.count
    }

    public func current() -> Character? {
        guard position < value.count else {
            return nil
        }
        let index = value.index(value.startIndex, offsetBy: position)
        return value[index]
    }

    public func advanced() -> StringInput {
        return StringInput(value, position: position + 1)
    }
}
