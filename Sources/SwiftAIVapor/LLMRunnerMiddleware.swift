import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AIRunnerMiddleware<PromptTemplateProvider: AIPromptTemplateProvider>: AsyncMiddleware, Sendable {
    public typealias CompletionClient = AICompletionClient<AIClient, PromptTemplateProvider>

    let models: [any AIModel]
    let promptTemplateProvider: PromptTemplateProvider
    let setupStorage: @Sendable (Request, CompletionClient) -> Void

    public init(
        models: [any AIModel],
        promptTemplateProvider: PromptTemplateProvider,
        setupStorage: @escaping @Sendable (Request, CompletionClient) -> Void
    ) {
        self.models = models
        self.setupStorage = setupStorage
        self.promptTemplateProvider = promptTemplateProvider
    }

    public func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {
        let runner = AICompletionClient(
            models: models,
            client: AIClient.self,
            promptTemplateProvider: promptTemplateProvider,
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
