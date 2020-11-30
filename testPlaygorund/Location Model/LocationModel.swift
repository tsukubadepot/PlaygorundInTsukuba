//
//  LocationModel.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/30.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import CoreLocation

class Coordinate: NSObject {
    // 初期値はつくば駅の座標
    var currentCoordinate = CLLocationCoordinate2D(latitude: 36.082131, longitude: 140.11141)
    
    // ロケーションマネージャ
    var locationManager = CLLocationManager()
    
    func setupLocationManager() {
        // 権限をリクエスト
        locationManager.requestWhenInUseAuthorization()
        
        // マネージャの設定
        let status = CLLocationManager.authorizationStatus()
        
        // ステータスごとの処理
        if status == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
    }
}

extension Coordinate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        currentCoordinate = location.coordinate
    }
}
