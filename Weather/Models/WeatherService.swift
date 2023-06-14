//
//  API.swift
//  Weather
//
//  Created by Эван Крошкин on 13.03.22.
//

import Foundation
import Combine
import CoreLocation

protocol WeatherServiceable {
    func fetchWeather(for cityName: String) -> AnyPublisher<WeatherResponse, Error>
}

class WeatherService: WeatherServiceable {
    
    enum ServiceError: Error {
  
        enum GeoCodeAdress: Error {
            case invalidCityName
            case emptyCity
            case cityNameTooSmall
            case invalidLocation
            
            var message: String {
                switch self {
                case .cityNameTooSmall:
                    return "City name should be minimum 4 characters"
                    
                case .emptyCity:
                    return "City name cannot be empty"
                    
                case .invalidCityName:
                    return "Entered city name does not exists. Please check the spelling and try again"
                    
                case .invalidLocation:
                    return "Invalid location for place!"

                }
            }
        }
    }
    
    static let key = Constants.Strings.keyAPI
    let client: APIClientFetchable
    
    init(client: APIClientFetchable = APIClient()) {
        self.client = client
    }
    
    private func fetchWeatherData(for latitude: Double, longitude: Double) -> AnyPublisher<WeatherResponse, Error> {
        client.fetch(request: APIType.weatherData(latitude: latitude, longitude: longitude))
    }
    
    private func fetchCoordinates1(for city: String) -> Future<CLLocationCoordinate2D, Error> {
        
        Future { promise in
            
            let trimmedString = city.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedString.isEmpty else {
                // throw city is empty error
                promise(.failure(ServiceError.GeoCodeAdress.emptyCity))
                return
            }
            
            guard trimmedString.count >= 4 else {
                // throw city name should be minimum 4 characters
                promise(.failure(ServiceError.GeoCodeAdress.cityNameTooSmall))
                return
            }
            
            CLGeocoder().geocodeAddressString(city) { (placemarks, error) in
                guard let places = placemarks,
                   let place = places.first else {
                    // city name invalid
                    promise(.failure(ServiceError.GeoCodeAdress.invalidCityName))
                    return
                }
                guard let location = place.location else {
                    // city name invalid
                    promise(.failure(ServiceError.GeoCodeAdress.invalidLocation))
                    return
                }
                promise(.success(location.coordinate))
            }
        }
    }
    
    private func fetchCoordinates(
        for city: String
    ) -> AnyPublisher<CLLocationCoordinate2D, Error> {
        
        Future { promise in
            
            let trimmedString = city.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedString.isEmpty else {
                // throw city is empty error
                promise(.failure(ServiceError.GeoCodeAdress.emptyCity))
                return
            }
            
            guard trimmedString.count >= 4 else {
                // throw city name should be minimum 4 characters
                promise(.failure(ServiceError.GeoCodeAdress.cityNameTooSmall))
                return
            }
            
            CLGeocoder().geocodeAddressString(city) { (placemarks, error) in
                guard let places = placemarks,
                      let place = places.first else {
                    // city name invalid
                    promise(.failure(ServiceError.GeoCodeAdress.invalidCityName))
                    return
                }
                guard let location = place.location else {
                    // city name invalid
                    promise(.failure(ServiceError.GeoCodeAdress.invalidLocation))
                    return
                }
                promise(.success(location.coordinate))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchWeather(for cityName: String) -> AnyPublisher<WeatherResponse, Error> {
        fetchCoordinates(for: cityName)
            .flatMap { coordinates -> AnyPublisher<WeatherResponse, Error> in
                self.fetchWeatherData(for: coordinates.latitude, longitude: coordinates.longitude)
            }
            .eraseToAnyPublisher()
    }
}
