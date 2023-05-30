//
//  APIRequest.swift
//  Weather
//
//  Created by Jaykumar on 2023-05-28.
//

import Foundation

enum HttpMethod: String {
    case get
    case post
    case put
    case delete
    
    var stringValue: String { rawValue.uppercased() }
}

protocol APIRequest {
    var baseURL: URL { get }
    var path: String { get }
    var httpMethod: HttpMethod { get }
    var queryParameters: [URLQueryItem]? { get }
    var body: Data? { get }
    var httpHeader: [String: String]? { get }
}

extension APIRequest {
    var body: Data? { nil }
    var httpHeader: [String: String]? { nil }
    var queryParameters: [URLQueryItem]? { nil }
}

extension APIRequest {
    var url: URL {
        let url = baseURL.appendingPathComponent(path)
        
        guard let paramters = queryParameters,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        
        components.queryItems = paramters
        return components.url ?? url
    }
    
    func asRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpBody = body
        request.allHTTPHeaderFields = httpHeader
        return request
    }
}
