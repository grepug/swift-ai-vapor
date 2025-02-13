import ConcurrencyUtils
import Dependencies
import SwiftAI
import SwiftAIServer
import Vapor

public struct AIClient: AIHTTPClient {
    public let prompt: String
    public let model: any AIModel

    public let stream: Bool

    @Dependency(\.request) var req

    public init(prompt: String, model: any AIModel, stream: Bool) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
    }

    public func request() async throws -> AsyncThrowingStream<String, any Error> {
        let request = ClientRequest(
            urlString: requestInfo.endpoint.absoluteString,
            method: .post,
            headers: [
                .authorization(bearer: model.apiKey),
                .contentTypeJSON,
            ],
            body: requestInfo.body
        )

        let (newStream, continuation) = AsyncThrowingStream<String, any Error>.makeStream()

        if stream {
            Task {
                let client = req.makeClient()
                let stream = client.stream(for: request)

                do {
                    for try await item in stream {
                        let item = item.replacingOccurrences(of: "data:", with: "")
                        let strings = decodeResponse(string: item)

                        for string in strings {
                            continuation.yield(string)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }

                try await client.shutdown()
            }
        } else {
            let client = req.makeClient()

            do {
                let response = try await client.data(for: request)
                let strings = decodeResponse(data: response)
                if let string = strings.first {
                    continuation.yield(string)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }

            try await client.shutdown()
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
    }
}
