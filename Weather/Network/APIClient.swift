//
//  APIClient.swift
//  Weather
//
//  Created by Jaykumar on 2023-05-28.
//

import Foundation
import Combine

struct APIClient: APIClientFetchable {
    
    private let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    func fetch<T: Codable>(request: APIRequest) -> AnyPublisher<T, Error> {
        
        let request = URLRequest(url: request.url)
        
        let dataTaskPublisher = URLSession.shared.dataTaskPublisher(for: request)
            .mapError { error -> Error in
                return APIError.transport(error: error)
            }
            .tryMap { (data, response) -> (data: Data, response: URLResponse) in
                print("Received response from server, now checking status code")
                
                guard let urlResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if (200..<300) ~= urlResponse.statusCode {
                    return (data, response)
                }
                else {
                    if (500..<600) ~= urlResponse.statusCode {
                        let retryAfter = urlResponse.value(forHTTPHeaderField: "Retry-After")
                        throw APIError.serverError(
                            statusCode: urlResponse.statusCode,
                            reason: "Retry",
                            retryAfter: retryAfter
                        )
                    }
                    throw APIError.invalidStatusCode
                }
            }
        
        return dataTaskPublisher
            .tryCatch { error -> AnyPublisher<(data: Data, response: URLResponse), Error> in
                guard case APIError.serverError = error else {
                    throw error
                }
                return Just(Void())
                    .delay(for: 3, scheduler: DispatchQueue.global())
                    .flatMap { _ in
                        return dataTaskPublisher
                    }
                    .print("before retry")
                    .retry(10)
                    .eraseToAnyPublisher()
            }
            .map(\.data)
            .tryMap { data -> T in
                let decoder = JSONDecoder()
                let string = String(decoding: data, as: UTF8.self)
                print(string)
                do {
                    return try decoder.decode(T.self, from: data)
                }
                catch {
                    throw APIError.decodingError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
