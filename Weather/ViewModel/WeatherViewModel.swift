//
//  WeatherViewModel.swift
//  Weather
//
//  Created by Эван Крошкин on 13.03.22.
//

import SwiftUI
import CoreLocation
import Combine

final class WeatherViewModel: ObservableObject {
    
    //MARK: - Properties
    
    typealias WeatherResult = Result<WeatherResponse, Error>
    let service: WeatherServiceable
    
    @Published var weather = WeatherResponse.empty()
//    @Published var city = Constants.Strings.city {
//        didSet {
//            getLocation()
//        }
//    }
    @Published var city = Constants.Strings.city
    @Published var showErrorAlert: Bool = false
    @Published var cityNameErrorMessage: String = ""

    private lazy var cityNameValidPublisher: AnyPublisher<WeatherResult, Never> = {
        $city
            .debounce(for: 0.8, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .print("cityName")
            .flatMap { cityName -> AnyPublisher<WeatherResult, Never> in
                self.service.fetchWeather(for: cityName).asResult()
            }
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()
    }()
    
    //MARK: - Init

    init(service: WeatherServiceable = WeatherService()) {
        self.service = service
        cityNameValidPublisher
            .map{ result in
                switch result {
                case .success(let weatherResponse):
                    self.weather = weatherResponse
                    return ""
                    
                case .failure(let error):
                    guard let cityNameError = error as? WeatherService.ServiceError.GeoCodeAdress else {
                        return ""
                    }
                    return cityNameError.message
                }
            }
            .assign(to: &$cityNameErrorMessage)
    }

//    init() {
//        getLocation()
//    }

    //MARK: - Methods

    private func getLocation() {
        CLGeocoder().geocodeAddressString(city) { (placemarks, error) in
            if let places = placemarks,
               let place = places.first {
                self.getWeather(coord: place.location?.coordinate)
            }
        }
    }

    private func getWeather(coord: CLLocationCoordinate2D?) {
        var urlString = ""
        if let coord = coord {
            urlString = WeatherService.getCurrentWeatherURL(latitude: coord.latitude, longitude: coord.longitude)
        } else {
            urlString = WeatherService.getCurrentWeatherURL(latitude: 53.9, longitude: 27.5667) // Minsk
        }
        getWeatherInternal(city: city, for: urlString)
    }

    private func getWeatherInternal(city: String, for urlString: String) {
        guard let url = URL(string: urlString) else {return}
        NetworkManager<WeatherResponse>.fetchWeather(for: url) { (result) in
            switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self.weather = response
                    }
                case .failure(let error):
                    print(error)
            }
        }
    }
    
    var date: String {
        return Time.defaultDateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(weather.current.date)) )
    }

    var weatherIcon: String {
        return weather.current.weather.first?.icon ?? "sun"
    }

    var temperature: String {
        return getTempFor(weather.current.temperature)
    }

    var conditions: String {
        return weather.current.weather.first?.main ?? ""
    }

    var windSpeed: String {
        return String(format: "%0.1f", weather.current.windSpeed)
    }

    var humidity: String {
        return String(format: "%d%%", weather.current.humidity)
    }

    var rainChances: String {
        return String(format: "%0.1f%%", weather.current.dewPoint)
    }

    func getTimeFor(_ temp: Int) -> String {
        return Time.timeFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(temp)))
    }

    func getDayFor(_ temp: Int) -> String {
        return Time.dayFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(temp)))
    }
    
    func getDayNumber(_ temp: Int) -> String {
        return Time.dayNumberFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(temp)))
    }

    func getTempFor(_ temp: Double) -> String {
        return String(format: "%1.0f", temp)
    }
    
    func getWeatherIconFor(icon: String) -> Image {
        switch icon {
            case "01d":
                return Image("sun")
            case "01n":
                return Image("moon")
            case "02d":
                return Image("cloudSun")
            case "02n":
                return Image("cloudMoon")
            case "03d":
                return Image("cloud")
            case "03n":
                return Image("cloudMoon")
            case "04d":
                return Image("cloudMax")
            case "04n":
                return Image("cloudMoon")
            case "09d":
                return Image("rainy")
            case "09n":
                return Image("rainy")
            case "10d":
                return Image("rainySun")
            case "10n":
                return Image("rainyMoon")
            case "11d":
                return Image("thunderstormSun")
            case "11n":
                return Image("thunderstormMoon")
            case "13d":
                return Image("snowy")
            case "13n":
                return Image("snowy-2")
            case "50d":
                return Image("tornado")
            case "50n":
                return Image("tornado")
            default:
                return Image("sun")
        }
    }
}
