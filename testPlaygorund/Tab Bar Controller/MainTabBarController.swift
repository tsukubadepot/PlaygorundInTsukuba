//
//  MainTabBarController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/25.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import NCMB
import Kingfisher
import MapKit
import FSPagerView

class MainTabBarController: UITabBarController {
    var parkModel = ParkModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // NCMB の初期化
        NCMB.initialize(applicationKey: applicationkey, clientKey: clientkey)
    }
}

extension MainTabBarController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parkModel.parks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ParkTableViewCell
        let park = parkModel.parks[indexPath.row]
        
        cell.imageThumbnailView.loadImage(forName: park.pictures.topImage)
        
        cell.parknameLabel.text = park.name
        cell.addressLabel.text = park.address
        cell.commentLabel.text = park.comments.comment
        
        switch park.playEquipments.count {
        case 0:
            // 遊具なし
            cell.equipmentCountLabel.text = "遊具なし"
        case 1:
            // 遊具1つ
            cell.equipmentCountLabel.text =  park.playEquipments.first!
        default:
            // 2つ以上
            cell.equipmentCountLabel.text = park.playEquipments.randomElement()! + "ほか" + String(park.playEquipments.count - 1) + "個"
        }
        
        return cell
    }
}

extension MainTabBarController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        
        vc.park = parkModel.parks[indexPath.row]
        vc.modelController = self
        
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        
        present(vc, animated: true, completion: nil)
    }
}

extension MainTabBarController: AnnotationMapViewDataSource {
    func numberOfAnnotations(in mapView: AnnotationMapView) -> Int {
        return parkModel.parks.count
    }
    
    func annotationMapView(_ mapView: AnnotationMapView, annotationFor: Int) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        let park = parkModel.parks[annotationFor]
        
        let lat = park.coordinate.latitude
        let lon = park.coordinate.longitude
        
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        annotation.coordinate = coordinate
        annotation.title = park.name
        annotation.subtitle = park.comments.comment
        
        return annotation
    }
    
    func firstIndex(ofName name: String) -> Int? {
        return parkModel.parks.firstIndex { park -> Bool in
            return park.name == name
        }
    }
}

extension MainTabBarController: FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return parkModel.parks.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        let park = parkModel.parks[index]
        
        
        guard let imageView = cell.imageView else {
            fatalError("cannot dequeue pagerView")
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.loadImage(forName: park.pictures.topImage)

        // 公園名
        // textLabel は最後に設定しないと ImageView の後ろになる
        cell.textLabel?.text = park.name

        return cell
    }
}
