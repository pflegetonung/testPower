//
//  WeatherViewModel.swift
//  weatherAppUIKitPowerTest
//
//  Created by Phillip on 15.05.2025.
//

import Foundation

final class WeatherViewModel {
    @Published private(set) var weather: WeatherResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let service = WeatherService()

    func fetch(lat: Double, lon: Double) {
        isLoading = true
        error = nil

        service.fetchWeather(lat: lat, lon: lon) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.weather = response
            case .failure(let err):
                self.error = err.localizedDescription
            }
        }
    }
}
