# ➡️  Decompose

[![Apache-2.0 License](https://img.shields.io/github/license/bluk/decompose.svg)](https://github.com/bluk/decompose/blob/master/LICENSE) [![Swift](https://img.shields.io/badge/swift-4.1-orange.svg)](https://swift.org) [![SPM Compatible](https://img.shields.io/badge/SPM-compatible-orange.svg)](https://github.com/apple/swift-package-manager) ![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)

[![Build Status](https://travis-ci.com/bluk/decompose.svg?branch=master)](https://travis-ci.com/bluk/decompose)

A(nother) parser combinator library inspired by
[Parsec: Direct Style Monadic Parser Combinators for the Real World](https://www.microsoft.com/en-us/research/people/daan/#!publications),
[Deterministic, Error-Correcting Combinator Parsers](http://www.staff.science.uu.nl/~swier101/Papers/1996/DetErrCorrComPars.pdf),
and [funcj.parser, Java parser combinator framework](https://github.com/typemeta/funcj/tree/master/parser).

## Getting Started

This package is intended for use with [Swift Package Manager](https://swift.org/package-manager/). To use in your
own package, add the following dependency:

```
dependencies: [
    .package(url: "https://github.com/bluk/decompose.git", from: "0.2.0")
]
```

Be sure to also add `Decompose` as a dependency in your `.target` like:

```
.target(
  name: "YourTarget",
  dependencies: ["Decompose"]),
```

In your code:

```
import DecomposeCore
import DecomposeOperators
```

## Documentation

* [API reference](https://bluk.github.io/decompose)

## Development

If you wish to modify this code, you can clone this repository and use
Swift Package Manager to build and test this code.

```
swift build
swift test
```

If you want to generate an Xcode project, you can run:

```
swift package generate-xcodeproj
```

### Generate Docs

To generate the documentation, you need Ruby installed, and then run:

```
bundle install
swift package generate-xcodeproj
jazzy -o docs/DecomposeCore --module "DecomposeCore" --module-version latest -g https://github.com/bluk/decompose
jazzy -o docs/DecomposeOperators --module "DecomposeOperators" --module-version latest -g https://github.com/bluk/decompose
jazzy -o docs/DecomposeJSON --module "DecomposeJSON" --module-version latest -g https://github.com/bluk/decompose
```

## Related Links

* [Parsec](https://hackage.haskell.org/package/parsec)
* [Parsec: Direct Style Monadic Parser Combinators for the Real World](https://www.microsoft.com/en-us/research/people/daan/#!publications)
* [Haskell/do notation](https://en.wikibooks.org/wiki/Haskell/do_notation)
* [ParsecJ: Java monadic parser combinator framework for constructing LL(1) parsers](https://github.com/jon-hanson/parsecj/)
* [Deterministic, Error-Correcting Combinator Parsers](http://www.staff.science.uu.nl/~swier101/Papers/1996/DetErrCorrComPars.pdf)
* [funcj.parser, Java parser combinator framework](https://github.com/typemeta/funcj/tree/master/parser)
* [Functional Swift](https://www.objc.io/books/functional-swift/)

## License

[Apache-2.0 License](https://github.com/bluk/decompose/blob/master/LICENSE)
