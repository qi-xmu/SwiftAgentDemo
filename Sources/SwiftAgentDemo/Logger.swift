//
//  Logger.swift
//  SwiftExeDemo
//
//  Created by Assistant on 2025/10/26.
//

import Foundation
import Logging

// 日志配置
extension Logger {
    static func configureLogging(name: String = "SwiftExeDemo") {
        // 获取当前工作目录
        let currentWorkingDirectory = FileManager.default.currentDirectoryPath
        let logFile = "\(currentWorkingDirectory)/\(name).log"

        // 配置日志系统
        LoggingSystem.bootstrap { label in
            // 创建自定义的日志处理器，写入文件但不输出到终端
            let fileHandler = FileLogHandler(label: label, logFile: logFile)

            // 返回多路日志处理器，优先使用文件处理器
            return MultiplexLogHandler([fileHandler])
        }
    }
}

// 文件日志处理器
struct FileLogHandler: LogHandler {
    let label: String
    let logFile: String

    init(label: String, logFile: String) {
        self.label = label
        self.logFile = logFile
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())

        let logEntry = "[\(timestamp)] [\(level)] [\(source)] \(message)\n"

        do {
            if FileManager.default.fileExists(atPath: logFile) {
                let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logFile))
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            } else {
                try logEntry.write(
                    to: URL(fileURLWithPath: logFile), atomically: true, encoding: .utf8)
            }
        } catch {
            // 静默处理文件写入错误，避免循环日志
        }
    }

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { return nil }
        set {}
    }

    var metadata: Logger.Metadata {
        get { return [:] }
        set {}
    }

    var logLevel: Logger.Level {
        get { return .trace }
        set {}
    }

    func getMetadata() -> Logger.Metadata {
        return [:]
    }

    func setMetadata(_ metadata: Logger.Metadata) {
        // 不实现
    }
}

// 多路日志处理器
struct MultiplexLogHandler: LogHandler {
    let handlers: [LogHandler]

    init(_ handlers: [LogHandler]) {
        self.handlers = handlers
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {

        for handler in handlers {
            handler.log(
                level: level, message: message, metadata: metadata, source: source, file: file,
                function: function, line: line)
        }
    }

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { return nil }
        set {}
    }

    var metadata: Logger.Metadata {
        get { return [:] }
        set {}
    }

    var logLevel: Logger.Level {
        get { return .trace }
        set {}
    }

    func getMetadata() -> Logger.Metadata {
        return [:]
    }

    func setMetadata(_ metadata: Logger.Metadata) {
        // 不实现
    }
}
