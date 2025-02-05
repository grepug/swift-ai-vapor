import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AIRunnerMiddleware: AsyncMiddleware, Sendable {
    let models: [any AIModel]
    let setupStorage: @Sendable (Request, AICompletionRunner<AIClient>) -> Void

    public init(
        models: [any AIModel],
        setupStorage: @escaping @Sendable (Request, AICompletionRunner<AIClient>) -> Void
    ) {
        self.models = models
        self.setupStorage = setupStorage
    }

    public func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {
        let runner = AICompletionRunner(
            models: models,
            client: AIClient.self
        )

        setupStorage(request, runner)

        return try await withDependencies {
            $0.request = request
        } operation: {
            try await responder.respond(to: request)
        }
    }
}
