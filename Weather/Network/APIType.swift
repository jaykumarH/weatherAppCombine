//
//  APIType.swift
//  Weather
//
//  Created by Jaykumar on 2023-05-29.
//

import Foundation

enum APIType {
    case weatherData(latitude: Double, longitude: Double)
    case cityNameCoordinate
}

extension APIType: APIRequest {
    
    var path: String {
        switch self {
        case .weatherData:
            return "/onecall"
            
        case .cityNameCoordinate:
            return ""
        }
    }
    
    var queryParameters: [URLQueryItem]? {
        var parameters: [URLQueryItem] = [
            URLQueryItem(name: "appid", value: "\(Constants.Strings.keyAPI)")
        ]
        switch self {
        case .cityNameCoordinate:
             break
            
        case .weatherData(let latitude, let longitude):
            parameters.append(
                contentsOf: [
                    URLQueryItem(name: "lat", value: "\(latitude)"),
                    URLQueryItem(name: "lon", value: "\(longitude)"),
                    URLQueryItem(name: "exclude", value: "minutely"),
                    URLQueryItem(name: "units", value: "metric")
                    
                ]
            )
        }
        return parameters
    }
    
    var httpMethod: HttpMethod {
        switch self {
        case .weatherData:
            return .get
            
        case .cityNameCoordinate:
            return .get
        }
    }
    
    var baseURL: URL {
        URL(string: Constants.Strings.url)!
    }
}
