// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

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

import PackageDescription

internal let package = Package(
    name: "Decompose",
    products: [
        .library(
            name: "Decompose",
            targets: ["DecomposeCore", "DecomposeOperators"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DecomposeCore",
            dependencies: []
        ),
        .testTarget(
            name: "DecomposeCoreTests",
            dependencies: ["DecomposeCore"]
        ),
        .target(
            name: "DecomposeOperators",
            dependencies: ["DecomposeCore"]
        ),
        .testTarget(
            name: "DecomposeOperatorsTests",
            dependencies: ["DecomposeOperators"]
        ),
        .target(
            name: "DecomposeJSON",
            dependencies: ["DecomposeCore", "DecomposeOperators"]
        ),
        .testTarget(
            name: "DecomposeJSONTests",
            dependencies: ["DecomposeJSON"]
        ),
    ]
)
