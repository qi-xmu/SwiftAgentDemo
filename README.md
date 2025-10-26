# Swift Agent 智能体框架

这是一个基于Swift实现的AI智能体框架，展示了如何构建具有自动工具调用能力的智能体系统。该框架支持与多种OpenAI兼容的API进行交互，并能够根据用户需求自动选择和执行工具，直到任务完成。

## 🌟 核心特性

- 🤖 **智能对话管理**：支持流式对话和上下文管理
- 🛠️ **自动工具调用**：智能体能够根据任务需求自动选择和执行工具
- 🔄 **递归任务处理**：支持多轮工具调用，直到任务完全完成
- 📡 **多模型支持**：兼容OpenAI、通义千问、DeepSeek、智谱AI等多种模型
- 🛡️ **类型安全**：基于Swift的类型系统，提供编译时类型检查
- 📝 **参数验证**：自动验证工具调用参数的类型和完整性
- 📊 **日志记录**：完整的日志系统，便于调试和监控

## 🏗️ 系统架构

```
SwiftAgentDemo/
├── Sources/SwiftExeDemo/
│   ├── Main.swift                 # 程序入口点
│   ├── Agent.swift               # 智能体核心实现
│   ├── FunctionToolReflection.swift # 工具反射和参数验证
│   ├── Functions.swift           # 工具函数实现
│   ├── OpenAICompatible.swift   # API兼容性层
│   ├── Config.swift              # 模型配置
│   └── Logger.swift              # 日志系统
└── Package.swift                 # Swift包配置
```

## 🚀 快速开始

### 环境要求

- macOS 10.15 或更高版本
- Swift 6.2 或更高版本
- Xcode 15.0 或更高版本（可选）

### 安装和运行

```bash
# 克隆项目
git clone <repository-url>
cd SwiftExeDemo

# 构建项目
swift build

# 运行智能体
swift run
```

## 💡 核心概念

### 1. 智能体 (Agent)

智能体是系统的核心组件，负责：
- 管理对话历史和上下文
- 解析用户意图
- 决策何时调用工具
- 处理工具执行结果
- 决定任务是否完成

### 2. 工具系统 (Tools)

工具是智能体执行具体任务的能力：

```swift
protocol FunctionTool {
    static var functionName: String { get }
    static var functionDescription: String { get }
    static var parameters: [ParameterDefinition] { get }
    static func execute(with arguments: [String: Any]) async throws -> String
}
```

### 3. 自动工具调用流程

1. **用户输入** → 智能体接收任务
2. **意图分析** → 判断是否需要工具
3. **工具选择** → 选择合适的工具
4. **参数生成** → 生成工具调用参数
5. **工具执行** → 执行工具并获取结果
6. **结果评估** → 判断任务是否完成
7. **循环处理** → 如需要，继续调用其他工具
8. **任务完成** → 返回最终结果

## 📚 使用示例

### 基本智能体使用

```swift
import Foundation

// 创建智能体实例
let assistant = WeatherAssistant(with: ModelConfig.Zai)

// 启动对话
await assistant.startConversation()
```

### 自定义工具

```swift
struct CalculatorTool: FunctionTool {
    static let functionName = "calculate"
    static let functionDescription = "执行数学计算"
    static let parameters = [
        ParameterDefinition(
            name: "expression",
            type: .string,
            description: "数学表达式，如 '2+3*4'"
        )
    ]
    
    static func execute(with arguments: [String: Any]) async throws -> String {
        guard let expression = arguments["expression"] as? String else {
            throw ToolError.invalidArguments("缺少表达式参数")
        }
        
        // 实现计算逻辑
        let result = evaluateExpression(expression)
        return "计算结果: \(expression) = \(result)"
    }
}

// 注册工具
ToolRegistry.shared.registerTool(CalculatorTool.self)
```

### 多工具协作示例

```swift
struct WeatherTool: FunctionTool {
    static let functionName = "get_weather"
    static let functionDescription = "获取指定城市的天气信息"
    static let parameters = [
        ParameterDefinition(
            name: "location",
            type: .string,
            description: "城市名称"
        )
    ]
    
    static func execute(with arguments: [String: Any]) async throws -> String {
        let location = arguments["location"] as! String
        // 模拟获取天气数据
        return "当前 \(location) 的天气是 25°C, 晴朗"
    }
}

struct TranslationTool: FunctionTool {
    static let functionName = "translate_text"
    static let functionDescription = "翻译文本到指定语言"
    static let parameters = [
        ParameterDefinition(name: "text", type: .string, description: "要翻译的文本"),
        ParameterDefinition(name: "target_language", type: .string, description: "目标语言")
    ]
    
    static func execute(with arguments: [String: Any]) async throws -> String {
        let text = arguments["text"] as! String
        let language = arguments["target_language"] as! String
        // 模拟翻译
        return "翻译结果: [\(language)] \(text)"
    }
}
```

## 🔧 配置说明

### 支持的模型配置

```swift
// 智谱AI
ModelConfig.Zai

// 通义千问
ModelConfig.Tongyi

// DeepSeek
ModelConfig.Deepseek
```

### 自定义模型配置

```swift
let customConfig = ModelConfig(
    host: "your-api-host.com",
    basePath: "/v1",
    apiKey: "your-api-key",
    modelName: "your-model-name",
    timeoutInterval: 30.0,
    extraBody: ["custom_parameter": .string("value")]
)
```

## 🔄 自动工具调用示例

智能体会自动处理复杂任务，例如：

**用户输入**: "查询厦门和郑州的天气，并将结果翻译成英文"

**智能体执行流程**:
1. 分析用户需求，识别需要天气查询和翻译两个任务
2. 调用 `get_weather` 工具查询厦门天气
3. 调用 `get_weather` 工具查询郑州天气
4. 调用 `translate_text` 工具翻译结果
5. 整合所有结果并返回给用户

## 🛠️ 扩展指南

### 添加新工具

1. 实现 `FunctionTool` 协议
2. 定义参数和执行逻辑
3. 注册到 `ToolRegistry`

```swift
struct MyCustomTool: FunctionTool {
    static let functionName = "my_tool"
    static let functionDescription = "我的自定义工具"
    static let parameters = [
        ParameterDefinition(name: "input", type: .string, description: "输入参数")
    ]
    
    static func execute(with arguments: [String: Any]) async throws -> String {
        // 实现你的逻辑
        return "处理结果"
    }
}

// 注册工具
ToolRegistry.shared.registerTool(MyCustomTool.self)
```

### 自定义智能体

```swift
class MyCustomAssistant: WeatherAssistant {
    override init(with config: ModelConfig, logger: Logger? = nil) {
        super.init(with: config, logger: logger)
        
        // 添加自定义工具
        toolManager.registerTool(MyCustomTool.self)
        functions = toolManager.getAllTools().map { .init(function: $0) }
    }
    
    // 自定义对话逻辑
    override func startConversation() async {
        // 实现你的对话逻辑
    }
}
```

## 📊 日志和调试

项目内置了完整的日志系统：

```swift
// 配置日志
Logger.configureLogging()

// 查看日志文件
// 日志文件位于项目根目录下的 SwiftExeDemo.log
```

日志内容包括：
- API请求和响应
- 工具调用详情
- 参数验证结果
- 错误信息

## 🎯 最佳实践

1. **工具设计**：保持工具功能单一，参数明确
2. **错误处理**：在工具中实现完善的错误处理
3. **参数验证**：利用内置的参数验证系统
4. **日志记录**：记录关键操作和错误信息
5. **上下文管理**：合理管理对话历史，避免上下文溢出

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

MIT License

## 🔗 相关资源

- [Swift官方文档](https://docs.swift.org/)
- [OpenAI API文档](https://platform.openai.com/docs/api-reference)
- [Swift Package Manager](https://swift.org/package-manager/)

---