import Foundation

/// 演示复杂参数校验
func demonstrateComplexParameterValidation() async {
    print("\n=== 演示复杂参数校验 ===")

    let toolMgr = ToolRegistry()

    // 定义一个具有多种参数类型的工具
    struct ComplexTool: FunctionTool {
        static let functionName = "complex_tool"
        static let functionDescription = "具有多种参数类型的复杂工具"
        static let parameters = [
            ParameterDefinition(name: "name", type: .string, description: "姓名"),
            ParameterDefinition(name: "age", type: .integer, description: "年龄"),
            ParameterDefinition(name: "score", type: .number, description: "分数"),
            ParameterDefinition(
                name: "isActive", type: .boolean, description: "是否激活", required: false),
            ParameterDefinition(name: "tags", type: .array, description: "标签数组", required: false),
            ParameterDefinition(
                name: "metadata", type: .object, description: "元数据对象", required: false),
        ]

        static func execute(with arguments: [String: Any]) async throws -> String {
            let name = arguments["name"] as! String
            let age = arguments["age"] as! Int
            let score = arguments["score"] as! Double
            let isActive = arguments["isActive"] as? Bool ?? true
            let tags = arguments["tags"] as? [String] ?? []
            let metadata = arguments["metadata"] as? [String: Any] ?? [:]

            return """
                复杂工具执行结果:
                姓名: \(name)
                年龄: \(age)
                分数: \(score)
                激活状态: \(isActive)
                标签: \(tags)
                元数据: \(metadata)
                """
        }
    }

    // 注册复杂工具
    toolMgr.registerTool(ComplexTool.self)
    toolMgr.listAllTools()

    // 测试正确的复杂参数
    print("🧪 测试正确的复杂参数")
    do {
        let result = try await toolMgr.executeTool(
            named: "complex_tool",
            with: """
                {
                    "name": "张三",
                    "age": 30,
                    "score": 95.5,
                    "isActive": true,
                    "tags": ["developer", "swift"],
                    "metadata": {"department": "技术部", "level": "高级"}
                }
                """
        )
        print("✅ 成功:\n\(result)")
    } catch {
        print("❌ 失败: \(error)")
    }

    print("\n" + String(repeating: "-", count: 50))

    // 测试类型错误的复杂参数
    print("🧪 测试类型错误的复杂参数")
    do {
        let result = try await toolMgr.executeTool(
            named: "complex_tool",
            with: """
                {
                    "name": "张三",
                    "age": "三十",
                    "score": 95.5,
                    "isActive": true
                }
                """
        )
        print("✅ 成功:\n\(result)")
    } catch {
        print("❌ 失败: \(error.localizedDescription)")
    }
}
