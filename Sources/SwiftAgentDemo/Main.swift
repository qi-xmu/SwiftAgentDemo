// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Logging
import OpenAI

@main
struct Main {
    static func main() async {
        // 配置日志系统
        Logger.configureLogging()
        let assistant = WeatherAssistant(with: ModelConfig.Zai)
        await assistant.startConversation()
    }
}
