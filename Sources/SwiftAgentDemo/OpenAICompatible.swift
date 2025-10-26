//
//  DoubaoModel.swift
//  AutoReminder
//
//  Created by qi on 2025/9/11.
//

import Foundation
import OpenAI

struct ModelConfig {
    var host: String
    var basePath: String
    var apiKey: String
    var modelName: String
    var timeoutInterval: Double?
    var extraBody: [String: JSONValue]? = nil
}

final class ModelClient: Sendable {
    static let shared = ModelClient()
    private init() {}

    static func getClient(config: ModelConfig) -> OpenAI {
        return OpenAI(
            configuration: .init(
                token: config.apiKey,
                host: config.host,
                basePath: config.basePath,
                timeoutInterval: config.timeoutInterval ?? 30,
                parsingOptions: .relaxed,
            )
        )
    }

    // func paramsVerify() async throws {
    //     let model = config.modelName
    //     let query = ChatQuery(
    //         messages: [.user(.init(content: .string("请回复：1")))],
    //         model: model,
    //     )

    //     let res = try await client.chats(query: query)
    //     print(res)
    // }
}
