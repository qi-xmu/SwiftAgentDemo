import Foundation
import OpenAI

/// 函数工具协议，用于自动生成 JSON Schema
protocol FunctionTool {
    /// 函数名称
    static var functionName: String { get }
    /// 函数描述
    static var functionDescription: String { get }
    /// 参数定义
    static var parameters: [ParameterDefinition] { get }
    /// 执行函数
    static func execute(with arguments: [String: Any]) async throws -> String
}

/// 参数定义
struct ParameterDefinition {
    let name: String
    let type: ParameterType
    let description: String
    let required: Bool

    init(name: String, type: ParameterType, description: String, required: Bool = true) {
        self.name = name
        self.type = type
        self.description = description
        self.required = required
    }
}

/// 参数类型
enum ParameterType {
    case string
    case number
    case integer
    case boolean
    case array
    case object

    var jsonSchemaType: JSONSchemaInstanceType {
        switch self {
        case .string: return .string
        case .number: return .number
        case .integer: return .integer
        case .boolean: return .boolean
        case .array: return .array
        case .object: return .object
        }
    }
}

/// 函数工具生成器
struct FunctionToolGenerator {
    /// 根据函数工具类型生成 JSON Schema
    static func generateParameters<T: FunctionTool>(for toolType: T.Type) -> JSONSchema {
        var properties: [String: JSONSchema] = [:]

        for param in toolType.parameters {
            properties[param.name] = JSONSchema.schema(
                .type(param.type.jsonSchemaType),
                .description(param.description)
            )
        }

        let required = toolType.parameters.filter { $0.required }.map { $0.name }

        return JSONSchema.schema(
            .type(.object),
            .properties(properties),
            .required(required),
            .additionalProperties(.boolean(false))
        )
    }

    /// 生成完整的工具定义
    static func generateTool<T: FunctionTool>(for toolType: T.Type, strict: Bool = false)
        -> ChatQuery.ChatCompletionToolParam.FunctionDefinition
    {
        return .init(
            name: toolType.functionName,
            description: toolType.functionDescription,
            parameters: generateParameters(for: toolType),
            strict: strict
        )
    }

    /// 执行工具函数
    static func executeTool<T: FunctionTool>(toolType: T.Type, with arguments: String) async throws
        -> String
    {
        guard let data = arguments.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw ToolError.invalidArguments("参数格式无效，无法解析为 JSON 对象")
        }

        // 使用 toolType.parameters 对参数进行校验
        try validateParameters(toolType.parameters, against: json)
        return try await toolType.execute(with: json)
    }

    /// 校验参数是否符合定义
    private static func validateParameters(
        _ parameters: [ParameterDefinition], against arguments: [String: Any]
    ) throws {
        // 1. 检查必需参数是否存在
        for param in parameters where param.required {
            if arguments[param.name] == nil {
                throw ToolError.invalidArguments("缺少必需参数: \(param.name)")
            }
        }

        // 2. 检查参数类型是否匹配
        for (key, value) in arguments {
            guard let paramDef = parameters.first(where: { $0.name == key }) else {
                throw ToolError.invalidArguments("未知参数: \(key)")
            }

            try validateParameterType(paramDef, value: value)
        }
    }

    /// 校验单个参数的类型
    private static func validateParameterType(_ paramDef: ParameterDefinition, value: Any) throws {
        switch paramDef.type {
        case .string:
            if !(value is String) {
                throw ToolError.invalidArguments(
                    "参数 '\(paramDef.name)' 应为字符串类型，实际为: \(type(of: value))")
            }

        case .number:
            if !(value is Double) && !(value is Int) {
                throw ToolError.invalidArguments(
                    "参数 '\(paramDef.name)' 应为数字类型，实际为: \(type(of: value))")
            }

        case .integer:
            if !(value is Int) {
                throw ToolError.invalidArguments(
                    "参数 '\(paramDef.name)' 应为整数类型，实际为: \(type(of: value))")
            }

        case .boolean:
            if !(value is Bool) {
                throw ToolError.invalidArguments(
                    "参数 '\(paramDef.name)' 应为布尔类型，实际为: \(type(of: value))")
            }

        case .array:
            if !(value is [Any]) {
                throw ToolError.invalidArguments(
                    "参数 '\(paramDef.name)' 应为数组类型，实际为: \(type(of: value))")
            }

        case .object:
            if !(value is [String: Any]) {
                throw ToolError.invalidArguments(
                    "参数 '\(paramDef.name)' 应为对象类型，实际为: \(type(of: value))")
            }
        }
    }
}

/// 工具执行错误
enum ToolError: Error, LocalizedError {
    case invalidArguments(String?)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            return message ?? "无效的参数格式"
        case .executionFailed(let message):
            return "执行失败: \(message)"
        }
    }
}

/// 通用工具注册器
class ToolRegistry: @unchecked Sendable {
    private var tools: [String: any FunctionTool.Type] = [:]

    func registerTool<T: FunctionTool>(_ toolType: T.Type) {
        tools[toolType.functionName] = toolType
    }

    func getAllTools() -> [ChatQuery.ChatCompletionToolParam.FunctionDefinition] {
        return tools.values.map { FunctionToolGenerator.generateTool(for: $0) }
    }

    func executeTool(named name: String, with arguments: String) async throws -> String {
        guard let toolType = tools[name] else {
            throw ToolError.executionFailed("未知工具: \(name)")
        }

        return try await FunctionToolGenerator.executeTool(toolType: toolType, with: arguments)
    }

    func listAllTools() {
        print("注册的工具列表:")
        for tool in tools.values {
            print("- \(tool.functionName)(")
            for param in tool.parameters {
                print(
                    "  \(param.name), type=\(param.type), required=\(param.required): \(param.description),"
                )
            }
            print("): \(tool.functionDescription)\n")
        }
    }
}
