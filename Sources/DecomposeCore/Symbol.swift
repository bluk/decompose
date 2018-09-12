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

/// Possible next symbols that can be accepted from the `Input`.
public enum Symbol<E>: Comparable, Hashable where E: Comparable, E: Hashable {

    #if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .all:
            hasher.combine("")
        case .empty:
            hasher.combine("")
        case let .predicate(name: name, _):
            hasher.combine(name)
        case let .value(value):
            hasher.combine(value)
        }
    }
    #else
    public var hashValue: Int {
        switch self {
        case .all:
            return "".hashValue
        case .empty:
            return "".hashValue
        case let .predicate(name: name, _):
            return name.hashValue
        case let .value(value):
            return value.hashValue
        }
    }
    #endif

    // swiftlint:disable cyclomatic_complexity function_body_length
    public static func < (lhs: Symbol<E>, rhs: Symbol<E>) -> Bool {
        // empty < all < value < predicate
        switch lhs {
        case .empty:
            switch rhs {
            case .empty:
                return false
            case .all:
                return true
            case .value:
                return true
            case .predicate:
                return true
            }
        case .all:
            switch rhs {
            case .empty:
                return false
            case .all:
                return false
            case .value:
                return true
            case .predicate:
                return true
            }
        case let .value(lhsValue):
            switch rhs {
            case .empty:
                return false
            case .all:
                return false
            case let .value(rhsValue):
                return lhsValue < rhsValue
            case .predicate:
                return true
            }
        case let .predicate(lhsPredicate):
            switch rhs {
            case .empty:
                return false
            case .all:
                return false
            case .value:
                return false
            case let .predicate(rhsPredicate):
                return lhsPredicate.name < rhsPredicate.name
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    public static func == (lhs: Symbol<E>, rhs: Symbol<E>) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case let (.value(lhsValue), .value(rhsValue)):
            return lhsValue == rhsValue
        case let (.predicate(lhsPredicate), .predicate(rhsPredicate)):
            return lhsPredicate.name == rhsPredicate.name
        case (.all, .all):
            return true
        default:
            return false
        }
    }

    /// A simple value.
    case value(E)

    /// A predicate/condition which must be met.
    case predicate(name: String, (E) -> Bool)

    /// A "no-op" value.
    case empty

    /// All values are accepted.
    case all

    public func matches(_ element: E) -> Bool {
        switch self {
        case let .value(currentValue):
            return currentValue == element
        case let .predicate(_, condition):
            return condition(element)
        case .all:
            return true
        case .empty:
            return false
        }
    }
}
