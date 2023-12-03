// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "MyLibrary",
  platforms: [
    .iOS(.v17),
    .macOS(.v11)
  ],
  products: [
    .library(name: "Model", targets: ["Model"]),
  ],
  dependencies: [
    .package(url: "git@github.com:apple/swift-format.git", from: "509.0.0"),
  ],
  targets: [
//    .plugin(
//      name: "SwiftFormatLintPlugin",
//      capability: .buildTool(),
//      dependencies: [
//        "SwiftFormatBinary"
//      ]
//    ),
//    .binaryTarget(
//      name: "SwiftFormatBinary",
//      path: "./artifactbundle/swift-format.artifactbundle"
//    ),
    .target(
      name: "Model"/*,
      plugins: [
        "SwiftFormatLintPlugin",
      ]*/
    ),
  ]
)
