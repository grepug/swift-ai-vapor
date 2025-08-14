import ConcurrencyUtils
import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AIClient: AIHTTPClient {
    public let prompt: String
    public let model: any AIModel
    public let stream: Bool
    public var timeout: TimeInterval

    @Dependency(\.request) var req

    public init(prompt: String, model: any AIModel, stream: Bool, timeout: TimeInterval) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
        self.timeout = timeout
    }

    public func request() async throws(AIHTTPClientError) -> AsyncThrowingStream<AIHTTPResponseChunk, any Error> {
        let request = ClientRequest(
            urlString: requestInfo.endpoint.absoluteString,
            method: .post,
            headers: [
                .authorization(bearer: model.apiKey),
                .contentTypeJSON,
            ],
            body: requestInfo.body
        )

        let (newStream, continuation) = AsyncThrowingStream<AIHTTPResponseChunk, any Error>.makeStream()

        if stream {
            Task {
                let client = req.makeClient(timeout: timeout)
                let stream = client.stream(for: request)

                do {
                    for try await item in stream {
                        let item = item.replacingOccurrences(of: "data:", with: "")
                        let chunks = try decodeResponse(string: item)

                        for chunk in chunks {
                            continuation.yield(chunk)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }

                try? await client.shutdown()
            }
        } else {
            let client = req.makeClient(timeout: timeout)

            do {
                let response = try await client.data(for: request)
                let chunks = try decodeResponse(data: response)
                if let chunk = chunks.first {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }

            try? await client.shutdown()
        }

        return newStream
    }
}

extension DependencyValues {
    var request: Request {
        get { self[RequestKey.self] }
        set { self[RequestKey.self] = newValue }
    }

    private enum RequestKey: DependencyKey {
        static var liveValue: Request {
            fatalError("Value of type \(Value.self) is not registered in this context")
        }

        static var testValue: Request {
            fatalError("Value of type \(Value.self) is not registered in this context")
        }
    }
}
