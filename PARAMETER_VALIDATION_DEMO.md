# 参数校验功能演示

## 🎯 功能概述

在执行工具之前，系统会使用 `toolType.parameters` 对传入的参数进行严格的校验，确保：

1. **必需参数检查** - 验证所有必需参数都已提供
2. **参数类型检查** - 验证参数类型与定义匹配
3. **未知参数检查** - 拒绝未定义的参数
4. **JSON 格式检查** - 确保参数是有效的 JSON

## 🔧 校验流程

```swift
// 1. 解析 JSON 参数
guard let data = arguments.data(using: .utf8),
      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
else {
    throw ToolError.invalidArguments("参数格式无效，无法解析为 JSON 对象")
}

// 2. 使用 toolType.parameters 对参数进行校验
try validateParameters(toolType.parameters, against: json)

// 3. 执行工具
return try await toolType.execute(with: json)
```

## 📋 校验规则

### 1. 必需参数校验
```swift
for param in parameters where param.required {
    if arguments[param.name] == nil {
        throw ToolError.invalidArguments("缺少必需参数: \(param.name)")
    }
}
```

### 2. 参数类型校验
```swift
switch paramDef.type {
case .string:
    if !(value is String) {
        throw ToolError.invalidArguments("参数 '\(paramDef.name)' 应为字符串类型，实际为: \(type(of: value))")
    }
case .number:
    if !(value is Double) && !(value is Int) {
        throw ToolError.invalidArguments("参数 '\(paramDef.name)' 应为数字类型，实际为: \(type(of: value))")
    }
// ... 其他类型
}
```

### 3. 未知参数校验
```swift
for (key, value) in arguments {
    guard let paramDef = parameters.first(where: { $0.name == key }) else {
        throw ToolError.invalidArguments("未知参数: \(key)")
    }
    // 继续类型校验...
}
```

## 🧪 测试用例

### ✅ 正确参数示例
```json
{
  "location": "北京"
}
```
**结果**: ✅ 校验通过，正常执行

### ❌ 缺少必需参数
```json
{}
```
**结果**: ❌ 抛出错误：`缺少必需参数: location`

### ❌ 参数类型错误
```json
{
  "location": 123
}
```
**结果**: ❌ 抛出错误：`参数 'location' 应为字符串类型，实际为: Int`

### ❌ 未知参数
```json
{
  "location": "北京",
  "unknown_param": "value"
}
```
**结果**: ❌ 抛出错误：`未知参数: unknown_param`

### ❌ JSON 格式错误
```
invalid json
```
**结果**: ❌ 抛出错误：`参数格式无效，无法解析为 JSON 对象`

## 🎯 支持的参数类型

| 参数类型 | Swift 类型 | 校验规则 |
|---------|-----------|---------|
| `.string` | `String` | 检查值是否为字符串 |
| `.number` | `Double`/`Int` | 检查值是否为数字类型 |
| `.integer` | `Int` | 检查值是否为整数 |
| `.boolean` | `Bool` | 检查值是否为布尔值 |
| `.array` | `[Any]` | 检查值是否为数组 |
| `.object` | `[String: Any]` | 检查值是否为字典 |

## 🚀 使用示例

### 定义带校验的工具
```swift
struct WeatherTool: FunctionTool {
    static let functionName = "get_weather"
    static let functionDescription = "获取天气信息"
    static let parameters = [
        ParameterDefinition(
            name: "location",
            type: .string,
            description: "城市名称，例如：北京、上海、纽约"
        )
    ]
    
    static func execute(with arguments: [String: Any]) async throws -> String {
        // 参数已经过校验，可以安全使用
        let location = arguments["location"] as! String
        let temperature = Int.random(in: 15...30)
        return "当前 \(location) 的温度是 \(temperature)°C。"
    }
}
```

### 执行工具（自动校验）
```swift
do {
    let result = try await ToolManager.executeTool(
        functionName: "get_weather",
        arguments: "{\"location\": \"北京\"}"
    )
    print("结果: \(result)")
} catch {
    print("校验失败: \(error)")
}
```

## ✨ 优势

### 1. 早期错误发现
- 在执行业务逻辑之前就发现参数错误
- 避免无效参数导致的运行时问题
- 提供清晰的错误信息

### 2. 类型安全
- 编译时定义参数类型
- 运行时严格类型检查
- 防止类型转换错误

### 3. 自动化
- 无需手动编写参数校验代码
- 根据参数定义自动生成校验逻辑
- 统一的错误处理机制

### 4. 易于维护
- 参数定义和校验逻辑分离
- 新增参数时自动获得校验支持
- 统一的错误消息格式

## 🔧 扩展指南

### 添加新的参数类型
1. 在 `ParameterType` 枚举中添加新类型
2. 在 `jsonSchemaType` 属性中添加对应的映射
3. 在 `validateParameterType` 方法中添加校验逻辑

### 自定义校验规则
可以扩展 `validateParameters` 方法来添加更复杂的校验规则：
- 参数值范围校验
- 字符串格式校验（如邮箱、电话号码）
- 数组长度限制
- 对象结构校验

这个参数校验系统确保了工具调用的安全性和可靠性，为构建稳定的 AI 工具生态系统提供了坚实的基础。