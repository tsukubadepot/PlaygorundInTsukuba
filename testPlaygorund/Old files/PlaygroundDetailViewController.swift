//
//  PlaygroundDetailViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/02/12.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import MapKit
import PKHUD

class PlaygroundDetailViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var nameTextLabel: UILabel!
    @IBOutlet weak var addressTextLabel: UILabel!
    @IBOutlet weak var facilityTextLabel: UITextView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var searchButton: UIButton!
    
    var playGroundInfo: PlayGround!
    
    // 現在位置 -> つくば駅
    var currentLatitude: Double!
    var currentLongitude: Double!
    
    // 公園のピン
    var toPin = MKPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PlaygroundDetailViewController: ", playGroundInfo.name)

        // Do any additional setup after loading the view.
        // ラベルを設定する
        nameTextLabel.text = playGroundInfo.name
        addressTextLabel.text = playGroundInfo.address
        facilityTextLabel.text = playGroundInfo.facility
        
        // 地図関連
        map.delegate = self
        // 公園の座標
        let targetCoordinate = CLLocationCoordinate2D(latitude: playGroundInfo.lat, longitude: playGroundInfo.lon)
        // ピンを立てる
        toPin.coordinate = targetCoordinate
        toPin.title = playGroundInfo.name
        self.map.addAnnotation(toPin)
        
        // addAnnotationsもある -> 地図上に複数の公園を表示する
        // MKDirectionsRequest で経路情報も描ける
        // https://orangelog.site/swift/mapkit-waypoints-route-direction/
        
        // 地図の表示
        self.map.region = MKCoordinateRegion(center: targetCoordinate, latitudinalMeters: 500.0, longitudinalMeters: 500.0)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // 移動手段
    var transportType: MKDirectionsTransportType = .automobile
    // 移動経路
    var myRoute: MKRoute! = nil

    // 移動手段の選択
    @IBAction func transportTypeSegment(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            // 自家用車
            transportType = .automobile
            
        case 1:
            // 徒歩
            transportType = .walking
            
        default:
            // 例外
            transportType = .any
            
        }
    }
    
    @IBAction func searchButton(_ sender: Any) {
        let fromPin = MKPointAnnotation()
        
        // 検索ボタンを無効化
        searchButton.isEnabled = false
        
        //
        HUD.flash(.progress)
        
        let targetCoordinate = CLLocationCoordinate2DMake(currentLatitude, currentLongitude)
        fromPin.coordinate = targetCoordinate
        fromPin.title = "現在地"
        map.addAnnotation(fromPin)
        
        // 現在あるピンを自動でズーム
        map.showAnnotations(map
            .annotations, animated: true)
        
        // 検索
        let directionsRequest = MKDirections.Request()
        var placemarks = [MKMapItem]()
        
        // 出発地と目的地を入れる
        var routeCoordinates: [CLLocationCoordinate2D] = []
        routeCoordinates.append(fromPin.coordinate)
        routeCoordinates.append(toPin.coordinate)
        
        // 古いオーバーレイを消す
        if let myRoute = myRoute {
            map.removeOverlay(myRoute.polyline)
        }
        //routeCoordinatesの配列からMKMapItemの配列にに変換
        for item in routeCoordinates {
            let placemark = MKPlacemark(coordinate: item, addressDictionary: nil)
            placemarks.append(MKMapItem(placemark: placemark))
        }
        
        // 移動手段の設定
        directionsRequest.transportType = transportType
        // 複数経路の移動なので書き換え必要
        
        directionsRequest.source = placemarks[0]
        directionsRequest.destination = placemarks[1] //目標地点
        let direction = MKDirections(request: directionsRequest)
        direction.calculate(completionHandler: {(response, error) in
            print(error) // Optional(Error Domain=MKErrorDomain Code=5 "(null)") など
            if error == nil {
                self.myRoute = response?.routes[0]
                // 更新には delegate を設定して mapview() を定義する必要がある
                self.map.addOverlay(self.myRoute.polyline, level: .aboveRoads) //mapViewに絵画
            }
            
            // 検索ボタンを有効にする
            self.searchButton.isEnabled = true
            
            HUD.hide()
        })
    }
    
    // MapView の delegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        return renderer
    }
}
