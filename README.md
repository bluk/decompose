# ➡️  Decompose

A(nother) parser combinator library inspired by
[Parsec: Direct Style Monadic Parser Combinators for the Real World][parsec_paper],
[Deterministic, Error-Correcting Combinator Parsers][deterministic_error_correcting_parsers],
and [funcj.parser, Java parser combinator framework][funcj_parser].

## Getting Started

This package is intended for use with [Swift Package Manager][spm]. To use in your
own package, add the following dependency:

```swift
dependencies: [
    .package(url: "https://github.com/bluk/decompose.git", from: "0.2.0")
]
```

Be sure to also add `Decompose` as a dependency in your `.target` like:

```swift
.target(
  name: "YourTarget",
  dependencies: ["Decompose"]),
```

In your code:

```swift
import DecomposeCore
import DecomposeOperators
```

## Documentation

* [API reference][api_reference]

## Development

If you wish to modify this code, you can clone this repository and use
Swift Package Manager to build and test this code.

```sh
swift build
swift test
```

If you want to generate an Xcode project, you can run:

```sh
swift package generate-xcodeproj
```

### Generate Docs

To generate the documentation, you need Ruby installed, and then run:

```sh
bundle install
swift package generate-xcodeproj
jazzy -o docs/DecomposeCore --module "DecomposeCore" --module-version latest -g https://github.com/bluk/decompose
jazzy -o docs/DecomposeOperators --module "DecomposeOperators" --module-version latest -g https://github.com/bluk/decompose
jazzy -o docs/DecomposeJSON --module "DecomposeJSON" --module-version latest -g https://github.com/bluk/decompose
```

## Related Links

* [Parsec][haskell_parsec]
* [Parsec: Direct Style Monadic Parser Combinators for the Real World][parsec_paper]
* [Haskell/do notation][haskell_do]
* [ParsecJ: Java monadic parser combinator framework for constructing LL(1) parsers][parsec_j]
* [Deterministic, Error-Correcting Combinator Parsers][deterministic_error_correcting_parsers]
* [funcj.parser, Java parser combinator framework][funcj_parser]
* [Functional Swift][functional_swift_book]

## License

[Apache-2.0 License][LICENSE]

[license]: LICENSE
[spm]: https://swift.org/package-manager/
[api_reference]: https://bluk.github.io/decompose
[haskell_parsec]: https://hackage.haskell.org/package/parsec
[parsec_paper]: https://www.microsoft.com/en-us/research/people/daan/#!publications
[parsec_j]: https://github.com/jon-hanson/parsecj/
[haskell_do]: https://en.wikibooks.org/wiki/Haskell/do_notation
[deterministic_error_correcting_parsers]: http://www.staff.science.uu.nl/~swier101/Papers/1996/DetErrCorrComPars.pdf
[funcj_parser]: https://github.com/typemeta/funcj/tree/master/parser
[functional_swift_book]: https://www.objc.io/books/functional-swift/
