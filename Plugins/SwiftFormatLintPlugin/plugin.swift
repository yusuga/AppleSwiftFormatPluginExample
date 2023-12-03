//
//  plugin.swift
//
//
//  Created by yusuga on 2023/12/02.
//

import Foundation
import PackagePlugin

private let pluginName = "swift-format"
private let targetFileExtension = "swift"

@main
struct SwiftFormatLintPlugin: BuildToolPlugin {

  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    guard let sourceTarget = target as? SourceModuleTarget else {
      return []
    }

    return createBuildCommands(
      inputFiles: sourceTarget
        .sourceFiles(withSuffix: targetFileExtension)
        .map(\.path),
      tool: try context.tool(named: pluginName)
    )
  }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftFormatLintPlugin: XcodeBuildToolPlugin {

  func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
    return createBuildCommands(
      inputFiles: target.inputFiles
        .filter { $0.type == .source && $0.path.extension == targetFileExtension }
        .map(\.path),
      tool: try context.tool(named: pluginName)
    )
  }
}
#endif

private extension SwiftFormatLintPlugin {

  func createBuildCommands(
    inputFiles: [Path],
    tool: PluginContext.Tool
  ) -> [Command] {
    [
      .buildCommand(
        displayName: pluginName,
        executable: tool.path,
        arguments: [
          "lint",
          "--parallel",
          "--recursive",
        ] + inputFiles.map(\.string)
      )
    ]
  }
}
