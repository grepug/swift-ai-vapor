import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AIRunnerMiddleware: AsyncMiddleware, Sendable {
    let models: [any AIModel]
    let setupStorage: @Sendable (Request, AICompletionRunner<AIClient>) -> Void
    let log: (@Sendable (String, Request) -> Void)?

    public init(
        models: [any AIModel],
        setupStorage: @escaping @Sendable (Request, AICompletionRunner<AIClient>) -> Void,
        log: (@Sendable (_ message: String, _ req: Request) -> Void)? = nil
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
            log: { message in
                log?(message, request)
            }
        )

        setupStorage(request, runner)

        return try await withDependencies {
            $0.request = request
        } operation: {
            try await responder.respond(to: request)
        }
    }
}
