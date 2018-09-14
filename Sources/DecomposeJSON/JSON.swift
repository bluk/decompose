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

import DecomposeCore
import DecomposeOperators
import Foundation

/// A representation of JSON elements
public enum JSONValue: Equatable {
    case object([String:JSONValue])
    case array([JSONValue])
    case string(String)
    case number(String, String, String)
    case literalNull
    case literalTrue
    case literalFalse

    public static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
        switch (lhs, rhs) {
        case let (.string(lhsValue), .string(rhsValue)):
            return lhsValue == rhsValue
        case let (.number(lhsValue), .number(rhsValue)):
            return lhsValue == rhsValue
        case let (.array(lhsValue), .array(rhsValue)):
            return lhsValue == rhsValue
        case let (.object(lhsValue), .object(rhsValue)):
            return lhsValue == rhsValue
        case (.literalNull, .literalNull):
            return true
        case (.literalTrue, .literalTrue):
            return true
        case (.literalFalse, .literalFalse):
            return true
        default:
            return false
        }
    }
}

/// The result from decoding JSON
public enum JSONResult {
    case success(JSONValue)
    case failure(Int, Set<String>)
}

internal let json: Parser<StringInput, JSONValue> = element

internal let value: Parser<StringInput, JSONValue> = Combinators.choice([
    object,
    array,
    string,
    number,
    Combinators.Text.string("true").map { _ in JSONValue.literalTrue },
    Combinators.Text.string("false").map { _ in JSONValue.literalFalse },
    Combinators.Text.string("null").map { _ in JSONValue.literalNull }
])

internal let object: Parser<StringInput, JSONValue> = Combinators
    .between(
        Combinators.Text.char("{"),
        Combinators.Text.whitespace().many() *> members <* Combinators.Text.whitespace().many(),
        Combinators.Text.char("}")
    )
    .map { values in JSONValue.object(values) }

internal let members: Parser<StringInput, [String: JSONValue]> = member.sepBy(
    Combinators.Text.whitespace().many() *> Combinators.Text.char(",") <* Combinators.Text.whitespace().many()
).map { values in
    values.reduce([:], { result, value in result.merging(value, uniquingKeysWith: { first, _ in first }) })
}

internal let member: Parser<StringInput, [String: JSONValue]> = { key in { value in
        if case let JSONValue.string(key) = key {
            return [key: value]
        }
        fatalError("Expected the key to be a string.")
    }
} <^>
    Combinators.Text.whitespace().many() *> string <*> Combinators.Text.whitespace().many()
    *> Combinators.Text.char(":") *> Combinators.Text.whitespace().many() *> element

internal let array: Parser<StringInput, JSONValue> = Combinators
    .between(
        Combinators.Text.char("["),
        Combinators.Text.whitespace().many() *> elements <* Combinators.Text.whitespace().many(),
        Combinators.Text.char("]")
    )
    .map { values in JSONValue.array(values) }

internal let elements: Parser<StringInput, [JSONValue]> = element.sepBy(
    Combinators.Text.whitespace().many() *> Combinators.Text.char(",") <* Combinators.Text.whitespace().many()
)

internal let element: Parser<StringInput, JSONValue> = Combinators.Text.whitespace().many()
    *> Parser<StringInput, JSONValue>.wrap { value } <* Combinators.Text.whitespace().many()

internal let string: Parser<StringInput, JSONValue> = Combinators
    .between(
        Combinators.symbol("\""),
        characters,
        Combinators.symbol("\"")
    )
    .map { JSONValue.string($0) }

internal let characters: Parser<StringInput, String> = character.many1().map { String($0) }.option("")

internal let character: Parser<StringInput, Character> = notControlCharactersOrQuoteOrSlash
    <|> Combinators.Text.char("\\")
        *> (Parser<StringInput, Character>.oneOf(["\\", "\"", "b", "n", "r", "t"]).map({ char in
            switch char {
            case "\\":
                return Character("\\")
            case "\"":
                return Character("\"")
            case "b":
                return Character(UnicodeScalar(8))
            case "n":
                return Character("\n")
            case "r":
                return Character("\r")
            case "t":
                return Character("\t")
            default:
                assertionFailure()
                return Character("")
            }
        })
        <|> { hexValues in
            let intValue = hexValues[0] << 12 | hexValues[1] << 8 | hexValues[2] << 4 | hexValues[3] << 0
            return Character(UnicodeScalar(intValue)!)
        } <^> Combinators.Text.char("u") *> Combinators.Text.hexadecimalAsInt().count(4)
)

internal let notControlCharactersOrQuoteOrSlash: Parser<StringInput, Character> = Combinators.satisfy(
conditionName: "not control character or quote or escape character") { char in
    let characterSet = CharacterSet.controlCharacters
    return char != "\"" && char != "\\" && !char.unicodeScalars.contains { characterSet.contains($0) }
}

internal let number: Parser<StringInput, JSONValue> = { int in { frac in { exp in
            JSONValue.number(int, frac, exp)
        }
    }
} <^> int <*> frac <*> exp

internal let int: Parser<StringInput, String> = Combinators.Text.char("0").map { value in String(value) }
    <|> Combinators
        .sequence([
            Combinators.symbol("-").map { [[$0]] },
            Combinators.Text.char("0").map { [[$0]] }
                <|> Combinators.sequence([
                    Combinators.Text.nonzeroDigit().map { [$0] },
                    Combinators.Text.digit().many()
                ])
        ])
        .map { String($0.flatMap { $0.flatMap { $0 } }) }
    <|> Combinators
        .sequence([
            Combinators.Text.nonzeroDigit().map { [$0] },
            Combinators.Text.digit().many()
        ])
        .map { String($0.flatMap { $0 }) }

internal let frac: Parser<StringInput, String> =
    (Combinators.symbol(".") *> Combinators.Text.digit().many1()).map { String($0) }.option("")

internal let exp: Parser<StringInput, String> =
    ({ sign in { digits in sign + digits } } <^> (Combinators.symbol("E") <|> Combinators.symbol("e"))
        *> Combinators.Text.sign().map { [$0] }.option([]) <*> Combinators.Text.digit().many1())
        .map { String($0) }.option("")

/// The JSON enum contains methods to process JSON.
public enum JSON {
    /// Decodes a JSON string.
    ///
    /// - Parameters:
    ///     - jsonString: The JSON in a string
    /// - Returns: A Result type with either the JSON value or the parsing failure position and expected symbols.
    public static func decode(_ jsonString: String) -> JSONResult {
        let result = json.parse(StringInput(jsonString))
        switch result {
        case let .success(_, value):
            return JSONResult.success(value)
        case let .failure(remainingInput, expectedSymbols):
            return JSONResult.failure(remainingInput.position, Set(expectedSymbols.map { "\($0)" }))
        case let .failureUnavailableInput(remainingInput, expectedSymbols):
            return JSONResult.failure(remainingInput.position, Set(expectedSymbols.map { "\($0)" }))
        }
    }
}
