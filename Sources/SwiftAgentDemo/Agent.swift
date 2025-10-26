import Foundation
import Logging
import OpenAI

struct ToolCaller {
    var id: String?
    var index: Int?
    var name: String?
    var arguments: String = ""

    typealias ToolCallParam =
        ChatQuery.ChatCompletionMessageParam.AssistantMessageParam.ToolCallParam
    func toToolCallParam() -> ToolCallParam {
        return .init(id: id!, function: .init(arguments: arguments, name: name!))
    }
}

final class WeatherAssistant {
    private let config: ModelConfig
    private let client: OpenAI
    private var conversationHistory: [ChatQuery.ChatCompletionMessageParam] = []
    private let functions: [ChatQuery.ChatCompletionToolParam]
    private let logger: Logger

    private let toolList = [WeatherTool.self]
    private let toolManager = ToolRegistry()

    init(with config: ModelConfig, logger: Logger? = nil) {
        self.client = ModelClient.getClient(config: config)
        self.config = config
        self.logger = logger ?? Logger(label: String(describing: Self.self))

        for tool in toolList {
            toolManager.registerTool(tool)
        }
        toolManager.listAllTools()

        self.functions = toolManager.getAllTools().map { .init(function: $0) }
    }

    func startConversation() async {
        print("🤖 智能体对话已启动，输入 'quit' 退出对话")

        conversationHistory.append(.user(.init(content: .string("查询厦门和郑州的天气"))))
        await streamProcessConversation()

        while false {
            print("\n💬 请输入您的问题: ", terminator: "")
            guard let userInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                continue
            }

            if userInput.lowercased() == "quit" {
                print("👋 再见！")
                break
            }

            if userInput.isEmpty {
                continue
            }

            // 添加用户消息到对话历史
            conversationHistory.append(.user(.init(content: .string(userInput))))

            // 处理对话
            // await processConversation()
            await streamProcessConversation()
        }
    }

    private func streamProcessConversation() async {
        var reasoning_message = ""
        var message = ""
        var toolCallers: [ToolCaller] = []

        let query = ChatQuery(
            messages: conversationHistory,
            model: config.modelName,
            tools: functions,
            extraBody: config.extraBody
        )

        if let jsonData = try? JSONEncoder().encode(query) {
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            logger.debug("Send query: \(jsonString)")
        }

        do {
            // 使用 for try await 循环处理流式响应
            var caller = ToolCaller()
            for try await result: ChatStreamResult in client.chatsStream(query: query) {
                logger.debug("\(result)")
                for choice in result.choices {
                    // 推理内容
                    if let reasoning = choice.delta.reasoning {
                        if reasoning_message.isEmpty {
                            print("\n[Reasoning]: ", terminator: "")
                        }
                        print("\(reasoning)", terminator: "")
                        fflush(stdout)
                        reasoning_message += reasoning
                    } else if let content = choice.delta.content {
                        // 处理流式响应中的内容
                        if reasoning_message != "" {
                            print("\n[Answer]: ", terminator: "")
                            reasoning_message = ""
                        }
                        print(content, terminator: "")
                        fflush(stdout)
                        message += content
                    }

                    // 处理工具调用
                    if let toolCalls = choice.delta.toolCalls, !toolCalls.isEmpty {
                        for toolCall in toolCalls {
                            if let id = toolCall.id {
                                if let cid = caller.id, cid != id {
                                    toolCallers.append(caller)
                                    caller = ToolCaller()
                                }
                                caller.id = id
                                caller.index = toolCall.index
                            }
                            // 完成工具调用后添加到对话历史
                            if let function = toolCall.function {
                                if let name = function.name {
                                    caller.name = name
                                }
                                if let arguments = function.arguments {
                                    caller.arguments += arguments
                                }
                            }

                        }
                    }

                    if let finishReason = choice.finishReason, finishReason == .toolCalls {
                        toolCallers.append(caller)

                        // 最终将AI回复添加到对话历史
                        self.conversationHistory.append(
                            .assistant(
                                .init(
                                    content: .textContent(message),
                                    toolCalls: toolCallers.map { $0.toToolCallParam() }
                                )
                            ))

                        print()
                        for caller in toolCallers {
                            let _ = await handleToolCall(caller)
                            print(" - ", caller)
                        }

                        await streamProcessConversation()
                    }

                    if let finishReason = choice.finishReason, finishReason == .stop {
                        logger.debug("流式响应完成")
                    }
                }
            }
        } catch {
            logger.error("❌ 错误: \(error)")
        }
    }

    private func processConversation() async {
        var shouldContinue = true

        while shouldContinue {
            let query = ChatQuery(
                messages: conversationHistory,
                model: config.modelName,
                tools: functions
            )

            do {
                let result = try await client.chats(query: query)
                logger.debug("收到响应: \(result)")
                // 添加记录到 conversationHistory
                conversationHistory.append(
                    .assistant(
                        .init(
                            content: .textContent(result.choices.first?.message.content ?? ""),
                            toolCalls: result.choices.first?.message.toolCalls
                        )
                    )
                )

                for choice in result.choices {
                    let message = choice.message

                    if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                        // 处理工具调用
                        for toolCall in toolCalls {
                            let _ = await handleToolCall(
                                .init(
                                    id: toolCall.id, index: 0, name: toolCall.function.name,
                                    arguments: toolCall.function.arguments))
                        }
                        // 工具调用后需要继续对话
                        shouldContinue = true
                    } else if let content = message.content {
                        // 显示AI回复
                        displayAIResponse(content)
                        shouldContinue = false
                    }
                }

            } catch {
                logger.error("❌ 错误: \(error)")
                shouldContinue = false
            }
        }
    }

    private func handleToolCall(
        _ toolCall: ToolCaller
    ) async -> String {
        guard let functionName = toolCall.name,
            let toolCallId = toolCall.id
        else {
            logger.error("工具调用缺少函数名称")
            return "工具调用失败"
        }
        let arguments = toolCall.arguments

        // 执行工具函数
        let result =
            (try? await toolManager.executeTool(
                named: functionName, with: arguments)) ?? "工具执行失败"

        logger.info("- 调用: \(functionName)(\(arguments))")
        logger.info("  结果: \(result)")

        conversationHistory.append(
            .tool(
                .init(
                    content: .textContent(result),
                    toolCallId: toolCallId,
                )))

        return result

    }

    private func displayAIResponse(_ content: String) {
        logger.info("🤖 AI回复: \(content)")
    }
}
