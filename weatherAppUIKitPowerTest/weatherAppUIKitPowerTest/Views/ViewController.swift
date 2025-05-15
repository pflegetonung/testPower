//
//  ViewController.swift
//  weatherAppUIKitPowerTest
//
//  Created by Phillip on 15.05.2025.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    private let viewModel = WeatherViewModel()
    private let locationManager = LocationManager()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let conditionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let hourlyScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let hourlyStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let dailyStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Refresh", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        button.layer.cornerRadius = 8
        button.isHidden = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        addGradientBackground()
        setupLayout()
        locationManager.onLocationUpdate = { [weak self] coordinate in
            self?.fetchWeather(for: coordinate.latitude, lon: coordinate.longitude)
            self?.resolveLocationName(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
        locationManager.startTracking()
        checkLocationAuthorization()
        bindViewModel()
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(locationLabel)
        view.addSubview(temperatureLabel)
        view.addSubview(conditionLabel)
        view.addSubview(hourlyScrollView)
        hourlyScrollView.addSubview(hourlyStackView)
        view.addSubview(dailyStackView)
        view.addSubview(refreshButton)

        NSLayoutConstraint.activate([
            locationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            locationLabel.bottomAnchor.constraint(equalTo: temperatureLabel.topAnchor, constant: -8),
            
            temperatureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            temperatureLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),

            conditionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            conditionLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 8),
            
            hourlyScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hourlyScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hourlyScrollView.topAnchor.constraint(equalTo: conditionLabel.bottomAnchor, constant: 20),
            hourlyScrollView.heightAnchor.constraint(equalToConstant: 100),

            hourlyStackView.leadingAnchor.constraint(equalTo: hourlyScrollView.leadingAnchor, constant: 16),
            hourlyStackView.trailingAnchor.constraint(equalTo: hourlyScrollView.trailingAnchor, constant: -16),
            hourlyStackView.topAnchor.constraint(equalTo: hourlyScrollView.topAnchor),
            hourlyStackView.bottomAnchor.constraint(equalTo: hourlyScrollView.bottomAnchor),
            hourlyStackView.heightAnchor.constraint(equalTo: hourlyScrollView.heightAnchor),
            
            dailyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dailyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dailyStackView.topAnchor.constraint(equalTo: hourlyScrollView.bottomAnchor, constant: 24),
            
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            refreshButton.widthAnchor.constraint(equalToConstant: 120),
            refreshButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func addGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemTeal.cgColor,
            UIColor.systemBlue.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func bindViewModel() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let weather = self.viewModel.weather {
                self.temperatureLabel.text = "\(weather.current.temp_c)°C"
                self.conditionLabel.text = weather.current.condition.text
                
                self.hourlyStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

                let hours = weather.forecast.forecastday.first?.hour ?? []
                let calendar = Calendar.current
                let currentHour = calendar.component(.hour, from: Date())

                for hour in hours {
                    let hourDate = ISO8601DateFormatter().date(from: hour.time.replacingOccurrences(of: " ", with: "T")) ?? Date()
                    let hourComponent = calendar.component(.hour, from: hourDate)
                    if hourComponent >= currentHour {
                        let view = self.makeHourlyView(hour: hour)
                        self.hourlyStackView.addArrangedSubview(view)
                    }
                }
                
                self.dailyStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

                for forecastDay in weather.forecast.forecastday {
                    let view = self.makeDailyView(forecastDay: forecastDay)
                    self.dailyStackView.addArrangedSubview(view)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self.viewModel.weather == nil {
                        self.refreshButton.isHidden = false
                    }
                }
            }
        }
    }
    
    private func makeHourlyView(hour: Hour) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.widthAnchor.constraint(equalToConstant: 60).isActive = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0

        let timeText = String(hour.time.suffix(5))
        label.text = "\(timeText)\n\(Int(hour.temp_c))°"

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
    
    private func makeDailyView(forecastDay: ForecastDay) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .left

        label.text = "\(forecastDay.date): \(Int(forecastDay.day.avgtemp_c))° - \(forecastDay.day.condition.text)"

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
    
    private func fetchWeather(for lat: Double, lon: Double) {
        viewModel.fetch(lat: lat, lon: lon)
    }
    
    private func resolveLocationName(from location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self = self else { return }
            if let name = placemarks?.first?.locality {
                self.locationLabel.text = name
            } else {
                self.locationLabel.text = "Moscow (Default)"
            }
        }
    }
    
    private func checkLocationAuthorization() {
        let status = CLLocationManager.authorizationStatus()
        if status == .denied || status == .restricted {
            let alert = UIAlertController(
                title: "Location Disabled",
                message: "To show local weather, please enable location access in Settings.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }))
            present(alert, animated: true)
        }
    }
    
    @objc private func refreshTapped() {
        locationManager.startTracking()
        refreshButton.isHidden = true
    }
}
