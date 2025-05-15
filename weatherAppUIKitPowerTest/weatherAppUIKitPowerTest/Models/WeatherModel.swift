//
//  WeatherModel.swift
//  weatherAppUIKitPowerTest
//
//  Created by Phillip on 15.05.2025.
//

import Foundation

struct WeatherResponse: Decodable {
    let current: Current
    let forecast: Forecast
}

struct Current: Decodable {
    let temp_c: Double
    let condition: Condition
}

struct Forecast: Decodable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Decodable {
    let date: String
    let hour: [Hour]
    let day: Day
}

struct Hour: Decodable {
    let time: String
    let temp_c: Double
    let condition: Condition
}

struct Day: Decodable {
    let avgtemp_c: Double
    let condition: Condition
}

struct Condition: Decodable {
    let text: String
    let icon: String
}
