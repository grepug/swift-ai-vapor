import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AICompletionMiddleware<E: AICompletionClientEventHandler>: AsyncMiddleware, Sendable {
    public typealias CompletionClient = AICompletionClient<AIClient, E>

    let modelProvider: @Sendable (_ request: Request) -> any AIModelProviderProtocol
    let promptTemplateProviders: @Sendable (_ request: Request) -> [any AIPromptTemplateProvider]
    let eventHandler: @Sendable (_ request: Request) -> E
    let setupStorage: @Sendable (Request, CompletionClient) -> Void

    public init(
        modelProvider: @Sendable @escaping (_ request: Request) -> any AIModelProviderProtocol,
        promptTemplateProviders: @Sendable @escaping (_ request: Request) -> [any AIPromptTemplateProvider],
        eventHandler: @Sendable @escaping (_ request: Request) -> E,
        setupStorage: @escaping @Sendable (Request, CompletionClient) -> Void
    ) {
        self.modelProvider = modelProvider
        self.setupStorage = setupStorage
        self.promptTemplateProviders = promptTemplateProviders
        self.eventHandler = eventHandler
    }

    public func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {
        return try await withDependencies {
            $0.request = request
        } operation: {
            let runner = CompletionClient(
                client: AIClient.self,
                modelProvider: modelProvider(request),
                promptTemplateProviders: promptTemplateProviders(request),
                eventHandler: eventHandler(request),
                logger: request.logger
            )

            setupStorage(request, runner)

            return try await responder.respond(to: request)
        }
    }
}
