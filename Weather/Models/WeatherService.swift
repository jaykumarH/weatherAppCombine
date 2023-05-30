//
//  API.swift
//  Weather
//
//  Created by Эван Крошкин on 13.03.22.
//

import Foundation
import Combine

class WeatherService {
    static let key = Constants.Strings.keyAPI
    let client: APIClientFetchable
    
    init(client: APIClientFetchable = APIClient()) {
        self.client = client
    }
    
    func fetchWeatherData(for latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        client.fetch(request: APIType.weatherData(latitude: latitude, longitude: longitude))
    }
}

extension WeatherService {
    static let baseURL = Constants.Strings.url
    
    static func getCurrentWeatherURL(latitude: Double, longitude: Double) -> String {
        let excludeFields = "minutely"
        return "\(baseURL)/onecall?lat=\(latitude)&lon=\(longitude)&appid=\(key)&exclude=\(excludeFields)&units=metric"
    }
}

final class NetworkManager<T: Codable> {
    static func fetchWeather(for url: URL, completion: @escaping (Result<T, NetworkError>) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard error == nil else {
                print(String(describing: error))
                if let error = error?.localizedDescription {
                    completion(.failure(.error(err: error)))
                }
                return
            }
            
            do {
                let json = try JSONDecoder().decode(T.self, from: data)
                completion(.success(json))
            } catch let err {
                print(String(describing: err))
                completion(.failure(.decodingError(err: err.localizedDescription)))
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case invalidResponse
    case invalidData
    case decodingError(err: String)
    case error(err: String)
}
