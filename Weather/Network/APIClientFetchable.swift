//
//  APIClient.swift
//  Weather
//
//  Created by Jaykumar on 2023-05-28.
//

import Foundation
import Combine

protocol APIClientFetchable {
    func fetch<T: Codable>(request: APIRequest) -> AnyPublisher<T, Error>
}
