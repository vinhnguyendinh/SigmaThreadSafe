//
//  ViewController.swift
//  SigmaTask
//
//  Created by Vinh Nguyen on 2019/10/02.
//  Copyright © 2019 GCS. All rights reserved.
//

import UIKit
import CoreLocation

enum QueueType: String {
    case T1 = "T1"
    case T2 = "T2"
    case T3 = "T3"
}

class ViewController: UIViewController {
    // MARK: - UI Properties
    
    // MARK: - Properties
    var queueOne: DispatchQueue?
    var queueTwo: DispatchQueue?
    var queueThree: DispatchQueue?
    
    var results: [String] = [] {
        didSet {
            self.handleCheckUpdateDataToServer()
        }
    }
    
    var locationTimer = Timer()
    var batteryTimer = Timer()
    
    let locationManager = CLLocationManager()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialData()
    }
    
    // MARK: - Config
    func initialData() {
        self.setupLocation()
        
        // Enable monitoring battery
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func setupLocation() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }
    }
    
    // MARK: - UI Actions
    @IBAction func startButtonClicked(_ sender: Any) {
        guard self.queueOne == nil,
            self.queueTwo == nil,
            self.queueThree == nil else {
                return
        }
        
        // Init threads
        self.queueOne = DispatchQueue(label: QueueType.T1.rawValue, attributes: .concurrent)
        self.queueTwo = DispatchQueue(label: QueueType.T2.rawValue, attributes: .concurrent)
        self.queueThree = DispatchQueue(label: QueueType.T3.rawValue, attributes: .concurrent)
        
        // Init timer
        self.locationTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(handleRequestLocation), userInfo: nil, repeats: true)
        self.batteryTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(handleRequestBattery), userInfo: nil, repeats: true)
    }
    
    @IBAction func stopButtonClicked(_ sender: Any) {
        self.queueOne = nil
        self.queueTwo = nil
        self.queueThree = nil
        
        self.locationTimer.invalidate()
        self.batteryTimer.invalidate()
    }
    
    // MARK: - Handler
    @objc func handleRequestLocation() {
        if CLLocationManager.locationServicesEnabled() {
            // Start updating location
            self.locationManager.startUpdatingLocation()
        }
    }
    
    @objc func handleRequestBattery() {
        // Safe thread to append new value battery to list string
        self.queueTwo?.async(flags: .barrier) { [weak self] in
            guard let `self` = self else {
                return
            }
            let battery = "\(UIDevice.current.batteryLevel)"
            self.results.append(battery)
        }
    }
    
    func handleCheckUpdateDataToServer() {
        self.queueThree?.sync { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.results.count > 5 {
                self.requestDataToServer()
            }
        }
    }
    
    func requestDataToServer() {
        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        let parameters: [String : Any] = [:]
        
        let network = Network(URLs.baseUrl)
        network.postItem("/test", parameters: parameters) { (isSuccess, data) in
            guard let dict = data as? [String: Any],
                isSuccess == true else {
                return
            }
            
            print(dict)
        }
    }
    
    
    // MARK: - Notifications
    
    
    // MARK: - Override functions
    
    // MARK: - Utils
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Stop updating location
        self.locationManager.stopUpdatingLocation()
        
        let geocoder = CLGeocoder()
        guard let currentLocation = locations.last else {
            return
        }
        
        print("longitude = \(currentLocation.coordinate.longitude) - latitude = \(currentLocation.coordinate.latitude)")
        
        // Reverse Geocoding
        print("Resolving the Address")
        
        guard #available(iOS 11.0, *)  else {
            // Fallback on earlier versions
            return
        }
        
        geocoder.reverseGeocodeLocation(currentLocation, preferredLocale: nil) { [weak self] (placemarks, error) in
            guard let `self` = self else {
                return
            }
            
            // Failure
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            // Success
            guard let placemarks = placemarks,
                let placemark = placemarks.last,
                placemarks.count > 0 else {
                    return
            }
            
            var address: String?
            
            // Sub thoroughfare
            if placemark.subThoroughfare?.count != 0 {
                address = placemark.subThoroughfare
            }
            
            // Thoroughfare
            if let thoroughfare = placemark.thoroughfare, thoroughfare.count > 0 {
                if let addressOld = address, addressOld.count > 0 {
                    address = "\(addressOld), \(thoroughfare)"
                } else {
                    address = thoroughfare
                }
            }
            
            // Postal code
            if let postalCode = placemark.postalCode, postalCode.count > 0 {
                if let addressOld = address, addressOld.count > 0 {
                    address = "\(addressOld), \(postalCode)"
                } else {
                    address = postalCode
                }
            }
            
            // Locality
            if let locality = placemark.locality, locality.count > 0 {
                if let addressOld = address, addressOld.count > 0 {
                    address = "\(addressOld), \(locality)"
                } else {
                    address = locality
                }
            }
            
            // Administrative area
            if let administrativeArea = placemark.administrativeArea, administrativeArea.count > 0 {
                if let addressOld = address, addressOld.count > 0 {
                    address = "\(addressOld), \(administrativeArea)"
                } else {
                    address = administrativeArea
                }
            }
            
            // Country
            if let country = placemark.country, country.count > 0 {
                if let addressOld = address, addressOld.count > 0 {
                    address = "\(addressOld), \(country)"
                } else {
                    address = country
                }
            }
            
            // Safe thread to append new value address to string list
            self.queueOne?.async(flags: .barrier) { [weak self] in
                guard let `self` = self, let address = address else {
                    return
                }
                self.results.append(address)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error update location: \(error.localizedDescription)")
    }
}
