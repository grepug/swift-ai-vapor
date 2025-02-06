import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AIRunnerMiddleware: AsyncMiddleware, Sendable {
    let models: [any AIModel]
    let setupStorage: @Sendable (Request, AICompletionRunner<AIClient>) -> Void
    let log: (@Sendable (String) -> Void)?

    public init(
        models: [any AIModel],
        setupStorage: @escaping @Sendable (Request, AICompletionRunner<AIClient>) -> Void,
        log: (@Sendable (String) -> Void)? = nil
    ) {
        self.models = models
        self.setupStorage = setupStorage
        self.log = log
    }

    public func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {
        let runner = AICompletionRunner(
            models: models,
            client: AIClient.self,
            log: log
        )

        setupStorage(request, runner)

        return try await withDependencies {
            $0.request = request
        } operation: {
            try await responder.respond(to: request)
        }
    }
}
