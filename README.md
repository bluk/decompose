# Decompose

[![Apache-2.0 License](https://img.shields.io/github/license/bluk/decompose.svg)](https://github.com/bluk/decompose/blob/master/LICENSE) [![Swift](https://img.shields.io/badge/swift-4.1-orange.svg)](https://swift.org) [![SPM Compatible](https://img.shields.io/badge/SPM-compatible-orange.svg)](https://github.com/apple/swift-package-manager) ![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)

[![Build Status](https://travis-ci.com/bluk/decompose.svg?branch=master)](https://travis-ci.com/bluk/decompose)

## Getting Started

This package is intended for use with [Swift Package Manager](https://swift.org/package-manager/). To use in your
own package, add the following dependency:

```
dependencies: [
    .package(url: "https://github.com/bluk/decompose.git", from: "0.1.0")
]
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
jazzy -o docs --module "decompose" --module-version <version> -g https://github.com/bluk/decompose
```

## License

[Apache-2.0 License](https://github.com/bluk/decompose/blob/master/LICENSE)
