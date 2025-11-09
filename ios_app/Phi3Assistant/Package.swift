// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Phi3Assistant",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .executable(
            name: "Phi3Assistant",
            targets: ["Phi3Assistant"]
        ),
    ],
    dependencies: [
        // ONNX Runtime for iOS
        .package(url: "https://github.com/microsoft/onnxruntime", from: "1.15.0"),
    ],
    targets: [
        .target(
            name: "Phi3Assistant",
            dependencies: [
                .product(name: "OnnxRuntime", package: "onnxruntime")
            ]
        ),
    ]
)