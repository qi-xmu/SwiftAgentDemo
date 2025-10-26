/*
 使用方法：

 1. 添加新工具：
    a. 创建实现 FunctionTool 协议的结构体
    b. 在 ToolRegistry 中注册新工具
    c. 新工具会自动包含在 getAllTools() 返回的列表中
 */

import OpenAI

// MARK: - 通用工具函数

class WeatherTool: FunctionTool {
    static let functionName = "get_weather"
    static let functionDescription = "获取天气信息"
    static let parameters = [
        ParameterDefinition(
            name: "location",
            type: .string,
            description: "城市名称"
        )
    ]

    static func execute(with arguments: [String: Any]) async throws -> String {
        let location = arguments["location"] as! String
        let weather = "25°C, 晴朗"  // 模拟天气数据
        return "当前 \(location) 的天气是 \(weather)"
    }
}
