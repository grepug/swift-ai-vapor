import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AIRunnerMiddleware: AsyncMiddleware, Sendable {
    public typealias CompletionClient = AICompletionClient<AIClient>

    let models: [any AIModel]
    let promptTemplateProviders: @Sendable (Request) -> [any AIPromptTemplateProvider]
    let setupStorage: @Sendable (Request, CompletionClient) -> Void

    public init(
        models: [any AIModel],
        promptTemplateProviders: @Sendable @escaping (Request) -> [any AIPromptTemplateProvider],
        setupStorage: @escaping @Sendable (Request, CompletionClient) -> Void
    ) {
        self.models = models
        self.setupStorage = setupStorage
        self.promptTemplateProviders = promptTemplateProviders
    }

    public func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {
        let runner = AICompletionClient(
            models: models,
            client: AIClient.self,
            promptTemplateProviders: promptTemplateProviders(request),
            logger: request.logger
        )

        setupStorage(request, runner)

        return try await withDependencies {
            $0.request = request
        } operation: {
            try await responder.respond(to: request)
        }
    }
}
