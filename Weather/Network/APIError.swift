//
//  APIError.swift
//  Weather
//
//  Created by Jaykumar on 2023-05-28.
//

import Foundation

enum APIError: Error {
    case transport(error: Error)
    case invalidStatusCode
    case invalidData
    case invalidResponse
    case serverError(statusCode: Int, reason: String? = nil, retryAfter: String? = nil)
    case decodingError(Error)
}
